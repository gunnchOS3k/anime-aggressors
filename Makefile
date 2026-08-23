# Anime Aggressors — repo-native targets

.PHONY: engineering-wave011 engineering-wave012 engineering-wave013b engineering-wave014 engineering-wave015 motion-promote wave015-human-crash-capture wave015-battlescene-stability

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

wave015-human-crash-capture:
	python3 tools/engineering_wave015/capture_human_play_crash.py

wave015-battlescene-stability:
	python3 tools/engineering_wave015/run_battlescene_stability.py

motion-promote:
	bash tools/motion_pipeline/production/promote_contribution.sh
