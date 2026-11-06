import struct
import sys
from pathlib import Path
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from build_weapon_text import bind,read_weapon_text


def record(ident,name,description='Açıklama'):
    raw=struct.pack('<H',ident)
    for text in [name,description,'0.5 Kg','15 mermi x 3','Yarı Otomatik']:
        encoded=(text+'\0').encode('utf-16le');raw+=struct.pack('<H',len(encoded)//2)+encoded
    return raw


class WeaponTextTests(unittest.TestCase):
    def test_full_five_string_record_and_truncation(self):
        raw=record(1001,'EM-92 FS');row=read_weapon_text(raw)[0]
        self.assertEqual(row['description'],'Açıklama');self.assertEqual(row['magazineText'],'15 mermi x 3')
        with self.assertRaisesRegex(ValueError,'Truncated'):read_weapon_text(raw[:-1])

    def test_name_or_id_alone_cannot_bind_a_different_weapon(self):
        weapons=[{'id':'ok','sourceId':1001,'name':'EM-92 FS'},{'id':'wrong-name','sourceId':1001,'name':'Other'},{'id':'wrong-id','sourceId':999,'name':'EM-92 FS'}]
        data=bind(record(1001,'EM-92 FS'),weapons)
        self.assertEqual(set(data['items']),{'ok'});self.assertFalse(data['numericGameplayStatsVerified'])
        self.assertFalse(bind(record(1001,'EM-92 FS')*2,weapons)['items'])


if __name__=='__main__':unittest.main()
