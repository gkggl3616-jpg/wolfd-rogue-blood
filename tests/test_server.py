import concurrent.futures
from http.client import HTTPConnection
import json
from pathlib import Path
import sys
import tempfile
import threading
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from server import Store, make_server

class StoreTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.store=Store(Path(self.temp.name)/'test.sqlite3')
        self.player=self.store.add_player('Test Kurt')
    def tearDown(self): self.temp.cleanup()
    def payload(self,currency='cash',request_id='request-1234'):
        return dict(playerId=self.player,currency=currency,amount=1000,reason='Test ödülü',requestId=request_id)
    def test_all_currencies_and_persistence(self):
        for currency in ('cash','kp','gold','gp'): self.store.grant(self.payload(currency,'request-'+currency))
        restored=Store(self.store.path).snapshot()
        self.assertEqual([restored['players'][0][c] for c in ('cash','kp','gold','gp')],[1000]*4)
        self.assertEqual(len(restored['logs']),4)
    def test_concurrent_duplicate_is_paid_once(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(lambda _: self.store.grant(self.payload()),range(12)))
        state=self.store.snapshot()
        self.assertEqual(state['players'][0]['cash'],1000)
        self.assertEqual(len(state['logs']),1)
    def test_invalid_grants_do_not_change_balance(self):
        for amount in (-1,0,1.5,True,1000001,'100'):
            with self.assertRaises(ValueError): self.store.grant(dict(self.payload(),amount=amount))
        with self.assertRaises(ValueError): self.store.grant(self.payload('unknown'))
        with self.assertRaises(ValueError): self.store.grant(dict(self.payload(),playerId='missing'))
        self.assertEqual(self.store.snapshot()['players'][0]['cash'],0)
        self.assertEqual(len(self.store.snapshot()['logs']),0)
    def test_request_id_reuse_rejected(self):
        self.store.grant(self.payload())
        with self.assertRaises(ValueError): self.store.grant(dict(self.payload(),amount=500))
        self.assertEqual(self.store.snapshot()['players'][0]['cash'],1000)
    def test_balance_cap_rollback(self):
        with self.store.connect() as db: db.execute('UPDATE players SET cash=1000000000')
        with self.assertRaises(ValueError): self.store.grant(self.payload())
        self.assertEqual(self.store.snapshot()['logs'],[])

class HTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory(); cls.port=18769
        cls.server=make_server(cls.port,cls.temp.name)
        cls.thread=threading.Thread(target=cls.server.serve_forever,daemon=True); cls.thread.start()
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown(); cls.server.server_close(); cls.thread.join(); cls.temp.cleanup()
    def request(self,path,body=None,headers=None):
        conn=HTTPConnection('127.0.0.1',self.port)
        conn.request('GET' if body is None else 'POST',path,body=None if body is None else json.dumps(body),headers=headers or {})
        response=conn.getresponse(); status=response.status; raw=response.read(); conn.close()
        return status,raw
    def test_browser_contract(self):
        status,raw=self.request('/api/state'); self.assertEqual(status,200); state=json.loads(raw)
        headers={'X-Admin-Token':state['token'],'Origin':f'http://localhost:{self.port}'}
        status,raw=self.request('/api/players',{'name':'HTTP Kurt'},headers); self.assertEqual(status,200)
        player=json.loads(raw)['id']
        payload=dict(playerId=player,currency='gp',amount=250,reason='API testi',requestId='http-test-123')
        self.assertEqual(self.request('/api/grants',payload,headers)[0],200)
        self.assertEqual(self.request('/api/grants',payload,headers)[0],200)
        state=json.loads(self.request('/api/state')[1]); self.assertEqual(state['players'][0]['gp'],250)
    def test_origin_and_token(self):
        self.assertEqual(self.request('/api/players',{'name':'Bad'})[0],403)
        self.assertEqual(self.request('/api/state',headers={'Host':'evil.example'})[0],403)
        self.assertEqual(self.request('/api/state',headers={'Origin':'https://evil.example'})[0],403)
        self.assertEqual(self.request('/../server.py')[0],404)
    def test_static_assets_and_actions(self):
        for path in ('/','/app.js','/style.css','/controls.json','/characters.json'): self.assertEqual(self.request(path)[0],200)
        controls=json.loads(self.request('/controls.json')[1])['controls']
        self.assertEqual(len(controls),139)
        self.assertEqual(sum(bool(c['bindings']) for c in controls),73)
        self.assertEqual(next(c for c in controls if c['action']=='Forward')['bindings'][0]['key'],'W')
    def test_godot_heartbeat_updates_connection_state(self):
        _,raw=self.request('/api/state',headers={'X-WolfRogue-Client':'godot'})
        self.assertTrue(json.loads(raw)['gameConnected'])

if __name__=='__main__': unittest.main()
