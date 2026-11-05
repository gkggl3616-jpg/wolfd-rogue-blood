import json
from pathlib import Path
import struct
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from build_map_catalog import SELECTED,match_links,read_modes,read_mode_maps


class MapTests(unittest.TestCase):
    def test_binary_records_reject_truncation(self):
        name='Destruction'.encode('utf-16le')
        mode=struct.pack('<HH',3001,len(name)//2)+name+bytes(16)
        link=struct.pack('<HBIBBH',3001,23,1,0,4,len(name)//2)+name+bytes(8)
        self.assertEqual(read_modes(mode)[0]['id'],3001)
        self.assertEqual(read_mode_maps(link)[0]['category'],4)
        for parser,data in [(read_modes,mode),(read_mode_maps,link)]:
            with self.assertRaises(ValueError):parser(data[:-1])

    def test_same_map_index_in_another_category_cannot_leak(self):
        links=[dict(modeId=1001,category=1,mapIndex=23),dict(modeId=3001,category=4,mapIndex=23)]
        attributes=[dict(category=1,mapIndex=23,path='worlds/other.dat',sourceOffset=10),dict(category=4,mapIndex=23,path='worlds/cappadocia.dat',sourceOffset=20)]
        rows,unknown=match_links('worlds/cappadocia.dat',links,attributes,{1001:{},3001:{}})
        self.assertEqual([r['modeId'] for r in rows],[3001])
        self.assertEqual(unknown,[])
        # Conflicting references for a key must not produce a guessed membership.
        attributes.append(dict(category=4,mapIndex=23,path='worlds/conflict.dat',sourceOffset=30))
        self.assertEqual(match_links('worlds/cappadocia.dat',links,attributes,{3001:{}})[0],[])

    def test_undefined_modes_and_similar_file_names_stay_out(self):
        attributes=[dict(category=1,mapIndex=3,path='worlds/gobekli_tepe_ramadan.dat',sourceOffset=20)]
        links=[dict(modeId=15000,category=1,mapIndex=3)]
        self.assertEqual(match_links('worlds/gobekli_tepe.dat',links,attributes,{})[0],[])
        rows,unknown=match_links('worlds/gobekli_tepe_ramadan.dat',links,attributes,{})
        self.assertEqual(rows,[])
        self.assertEqual([r['modeId'] for r in unknown],[15000])

    def test_selected_catalog_has_exact_user_selection_and_reciprocal_links(self):
        raw=(ROOT/'godot/assets/maps/catalog.json').read_bytes()
        for path in ['docs/selected-map-modes.json','web/maps.json']:
            self.assertEqual(raw,(ROOT/path).read_bytes())
        catalog=json.loads(raw);maps={m['number']:m for m in catalog['maps']};modes={m['id']:m for m in catalog['modes']}
        self.assertEqual(set(maps),set(SELECTED))
        self.assertEqual(catalog['selection'],list(SELECTED))
        self.assertEqual(sum(bool(m['allowedModeIds']) for m in maps.values()),len(SELECTED)-2)
        self.assertEqual(maps[46]['allowedModeIds'],[])
        self.assertNotIn(47,maps)
        self.assertEqual(set(maps[26]['allowedModeIds']),{3000,3001,3020,3021})
        self.assertEqual(set(maps[72]['allowedModeIds']),{6005,6010,6015})
        for number,entry in maps.items():
            self.assertFalse(entry['enabled'])
            self.assertIsNone(entry['asset'])
            for mode_id in entry['allowedModeIds']:
                self.assertIn(number,modes[mode_id]['mapNumbers'])
                self.assertTrue(any(e['modeId']==mode_id for e in entry['modeEvidence']))
        for mode_id,mode in modes.items():
            self.assertEqual(mode['implementationStatus'],'catalog_only')
            for number in mode['mapNumbers']:self.assertIn(mode_id,maps[number]['allowedModeIds'])


if __name__=='__main__':unittest.main()
