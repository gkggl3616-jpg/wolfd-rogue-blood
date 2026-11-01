"""Wolf Rogue Blood local development panel. Python 3.10+, no dependencies."""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import secrets
import sqlite3
import uuid

ROOT = Path(__file__).resolve().parent
CURRENCIES = ('cash', 'kp', 'gold', 'gp')
MAX_BALANCE = 1_000_000_000

class Store:
    def __init__(self, path):
        self.path = str(path)
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.executescript('''
                CREATE TABLE IF NOT EXISTS players (
                    id TEXT PRIMARY KEY, name TEXT NOT NULL,
                    cash INTEGER NOT NULL DEFAULT 0 CHECK(cash BETWEEN 0 AND 1000000000),
                    kp INTEGER NOT NULL DEFAULT 0 CHECK(kp BETWEEN 0 AND 1000000000),
                    gold INTEGER NOT NULL DEFAULT 0 CHECK(gold BETWEEN 0 AND 1000000000),
                    gp INTEGER NOT NULL DEFAULT 0 CHECK(gp BETWEEN 0 AND 1000000000));
                CREATE TABLE IF NOT EXISTS grants (
                    request_id TEXT PRIMARY KEY, player_id TEXT NOT NULL REFERENCES players(id),
                    currency TEXT NOT NULL, amount INTEGER NOT NULL, reason TEXT NOT NULL,
                    created_at TEXT NOT NULL, balance_after INTEGER NOT NULL);
            ''')

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA foreign_keys=ON')
        try:
            with db:
                yield db
        finally:
            db.close()

    def snapshot(self):
        with self.connect() as db:
            players=[dict(r) for r in db.execute('SELECT * FROM players ORDER BY rowid DESC')]
            logs=[dict(r) for r in db.execute('SELECT g.*,p.name FROM grants g JOIN players p ON p.id=g.player_id ORDER BY g.rowid DESC LIMIT 100')]
        return dict(players=players, logs=logs, mode='local-development', gameConnected=False)

    def add_player(self, name):
        if not isinstance(name, str) or not 2 <= len(name.strip()) <= 32:
            raise ValueError('Oyuncu adı 2–32 karakter olmalı.')
        if any(ord(c)<32 for c in name): raise ValueError('Geçersiz oyuncu adı.')
        player_id=uuid.uuid4().hex
        with self.connect() as db:
            db.execute('INSERT INTO players(id,name) VALUES(?,?)',(player_id,name.strip()))
        return player_id

    def grant(self, payload):
        currency=payload.get('currency')
        amount=payload.get('amount')
        reason=payload.get('reason')
        player=payload.get('playerId')
        request_id=payload.get('requestId')
        if currency not in CURRENCIES: raise ValueError('Geçersiz bakiye türü.')
        if type(amount) is not int or not 1 <= amount <= 1_000_000:
            raise ValueError('Miktar 1–1.000.000 arasında tam sayı olmalı.')
        if not isinstance(reason,str) or not 3 <= len(reason.strip()) <= 160:
            raise ValueError('İşlem açıklaması 3–160 karakter olmalı.')
        if not isinstance(player,str): raise ValueError('Oyuncu seç.')
        if not isinstance(request_id,str) or not 8 <= len(request_id) <= 80:
            raise ValueError('İşlem kimliği geçersiz.')
        with self.connect() as db:
            db.execute('BEGIN IMMEDIATE')
            previous=db.execute('SELECT * FROM grants WHERE request_id=?',(request_id,)).fetchone()
            if previous:
                if (previous['player_id'],previous['currency'],previous['amount'],previous['reason']) != (player,currency,amount,reason.strip()):
                    raise ValueError('İşlem kimliği başka bir istek için kullanılmış.')
                return dict(previous)
            row=db.execute('SELECT * FROM players WHERE id=?',(player,)).fetchone()
            if not row: raise ValueError('Oyuncu bulunamadı.')
            balance=row[currency]+amount
            if balance>MAX_BALANCE: raise ValueError('Bakiye sınırı aşıldı.')
            db.execute(f'UPDATE players SET {currency}=? WHERE id=?',(balance,player))
            now=datetime.now(timezone.utc).isoformat()
            db.execute('INSERT INTO grants VALUES(?,?,?,?,?,?,?)',(request_id,player,currency,amount,reason.strip(),now,balance))
            return dict(request_id=request_id,player_id=player,currency=currency,amount=amount,reason=reason.strip(),created_at=now,balance_after=balance)

def make_server(port=8765, data_dir=None):
    store=Store((Path(data_dir) if data_dir else ROOT/'data')/'players.sqlite3')
    token=secrets.token_urlsafe(32)
    allowed_hosts={f'localhost:{port}',f'127.0.0.1:{port}'}
    allowed_origins={f'http://{host}' for host in allowed_hosts}

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args): pass

        def send(self,status,content,mime='application/json; charset=utf-8'):
            if not isinstance(content,bytes): content=json.dumps(content,ensure_ascii=False).encode()
            self.send_response(status)
            self.send_header('Content-Type',mime)
            self.send_header('Content-Length',str(len(content)))
            self.send_header('Cache-Control','no-store')
            self.send_header('X-Content-Type-Options','nosniff')
            self.send_header('X-Frame-Options','DENY')
            self.send_header('Content-Security-Policy',"default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")
            self.end_headers(); self.wfile.write(content)

        def trusted(self):
            return self.headers.get('Host') in allowed_hosts and self.headers.get('Origin') in (None,*allowed_origins)

        def do_GET(self):
            if not self.trusted(): return self.send(403,dict(error='Yalnızca yerel erişim.'))
            route=self.path.split('?')[0]
            if route=='/api/state': return self.send(200,dict(**store.snapshot(),token=token))
            paths={'/':'index.html','/app.js':'app.js','/style.css':'style.css','/controls.json':'controls.json','/characters.json':'characters.json'}
            file=paths.get(route)
            if not file: return self.send(404,dict(error='Sayfa bulunamadı.'))
            mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8'}[Path(file).suffix]
            self.send(200,(ROOT/'web'/file).read_bytes(),mime)

        def do_POST(self):
            if not self.trusted() or not secrets.compare_digest(self.headers.get('X-Admin-Token',''),token):
                return self.send(403,dict(error='Yerel oturum doğrulanamadı. Sayfayı yenile.'))
            try:
                length=int(self.headers.get('Content-Length',0))
                if not 0<length<=8192: raise ValueError('İstek boyutu geçersiz.')
                payload=json.loads(self.rfile.read(length))
                if not isinstance(payload,dict): raise ValueError('Geçersiz istek.')
                if self.path=='/api/players': result=dict(id=store.add_player(payload.get('name')))
                elif self.path=='/api/grants': result=store.grant(payload)
                else: return self.send(404,dict(error='İşlem bulunamadı.'))
                self.send(200,result)
            except (ValueError,TypeError,UnicodeError):
                import sys
                err=sys.exc_info()[1]
                self.send(400,dict(error=str(err)))
            except sqlite3.Error:
                self.send(500,dict(error='Kayıt tamamlanamadı. Aynı işlemi tekrar deneyebilirsin.'))

    server=ThreadingHTTPServer(('127.0.0.1',port),Handler)
    return server

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--port',type=int,default=8765); parser.add_argument('--data-dir',type=Path)
    args=parser.parse_args()
    if not 1024<=args.port<=65535: parser.error('Port 1024–65535 arasında olmalı.')
    server=make_server(args.port,args.data_dir)
    print(f'Wolf Rogue Blood: http://localhost:{args.port}',flush=True)
    try: server.serve_forever()
    except KeyboardInterrupt: pass
    finally: server.server_close()
