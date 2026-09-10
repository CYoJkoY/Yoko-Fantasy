"""Translation regressions runnable without a copy of the game."""
import csv
from pathlib import Path
import re
import unittest


class GermanEffectTextTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        path = Path(__file__).resolve().parents[1] / "translations" / "Fantasy.csv"
        with path.open(encoding="utf-8", newline="") as source:
            cls.rows = {row["keys"]: row for row in csv.DictReader(source)}

    def test_synthesis_chance_keeps_percent_unit(self):
        for key in (
            "EFFECT_FANTASY_SHOP_ENTER_SYNTHESIS",
            "EFFECT_FANTASY_GEAR_SHOP_ENTER_SYNTHESIS",
        ):
            with self.subTest(key=key):
                text = self.rows[key]["de"].format("30", "6 Schwerter", "Heldenschwert", "BONUS")
                self.assertIn("30%", text)
                self.assertIn("6 Schwerter", text)
                self.assertIn("Heldenschwert", text)
                self.assertIn("BONUS", text)

    def test_set_bonus_keeps_current_total(self):
        row = self.rows["EFFECT_FANTASY_SPECIFIC_SET_WEAPON_BONUSES"]
        self.assertEqual(set(re.findall(r"\{\d+\}", row["en"])),
                         set(re.findall(r"\{\d+\}", row["de"])))
        text = row["de"].format("2", "Schaden", "Klinge", "6", "1")
        self.assertIn("aktuell: 6", text)


if __name__ == "__main__":
    unittest.main()
