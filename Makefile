# Anime Aggressors — repo-native targets

.PHONY: engineering-wave011 engineering-wave012 engineering-wave013b engineering-wave014 motion-promote

engineering-wave011:
	bash tools/engineering_wave011/run_wave011.sh

engineering-wave012:
	bash tools/engineering_wave012/run_wave012.sh

engineering-wave013b:
	bash tools/engineering_wave013b/run_wave013b.sh

engineering-wave014:
	bash tools/engineering_wave014/run_wave014.sh

motion-promote:
	bash tools/motion_pipeline/production/promote_contribution.sh
