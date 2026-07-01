using UnrealBuildTool;
using System.Collections.Generic;

public class AnimeAggressorsArenaTarget : TargetRules
{
	public AnimeAggressorsArenaTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V4;
		ExtraModuleNames.Add("AnimeAggressorsArena");
	}
}
