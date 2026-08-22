# Anime Aggressors — repo-native targets

.PHONY: engineering-wave011 engineering-wave012 engineering-wave013b motion-promote

engineering-wave011:
	bash tools/engineering_wave011/run_wave011.sh

engineering-wave012:
	bash tools/engineering_wave012/run_wave012.sh

engineering-wave013b:
	bash tools/engineering_wave013b/run_wave013b.sh

motion-promote:
	bash tools/motion_pipeline/production/promote_contribution.sh
