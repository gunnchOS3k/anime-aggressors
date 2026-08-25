# Anime Aggressors — repo-native targets

.PHONY: engineering-wave011 engineering-wave012 engineering-wave013b engineering-wave014 engineering-wave015 engineering-wave016 engineering-wave017 engineering-wave018 engineering-wave019 motion-promote wave015-human-crash-capture wave015-battlescene-stability taste-gate engineering-taste-gate

engineering-wave011:
	bash tools/engineering_wave011/run_wave011.sh

engineering-wave012:
	bash tools/engineering_wave012/run_wave012.sh

engineering-wave013b:
	bash tools/engineering_wave013b/run_wave013b.sh

engineering-wave014:
	bash tools/engineering_wave014/run_wave014.sh

engineering-wave015:
	bash tools/engineering_wave015/run_wave015.sh

engineering-wave016:
	bash tools/engineering_wave016/run_wave016.sh

engineering-wave017:
	bash tools/engineering_wave017/run_wave017.sh

engineering-wave018:
	bash tools/engineering_wave018/run_wave018.sh

engineering-wave019:
	bash tools/engineering_wave019/run_wave019.sh

wave015-human-crash-capture:
	python3 tools/engineering_wave015/capture_human_play_crash.py

wave015-battlescene-stability:
	python3 tools/engineering_wave015/run_battlescene_stability.py

motion-promote:
	bash tools/motion_pipeline/production/promote_contribution.sh

# Game Taste Gate — placeholder detect + model visibility static + report emit.
# Does not invent Pixel evidence or assign HUMAN_Q5.
taste-gate engineering-taste-gate:
	python3 tools/quality/check_placeholder_visuals.py
	python3 tools/quality/check_model_visibility_reliability.py
	python3 tools/quality/emit_taste_gate_report.py
