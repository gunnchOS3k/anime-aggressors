import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createDefaultCareerProfile,
  createDefaultFighterStats,
  applyMatchRecordToCareer,
  buildMatchRecordFromEvents,
  computeWinRate,
  computeHitAccuracy,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  type StatEvent,
} from "../src/index.js";

describe("career stats", () => {
  it("career starts at zero", () => {
    const career = createDefaultCareerProfile("Test");
    assert.equal(career.totalMatches, 0);
    assert.equal(career.totalKOs, 0);
    assert.equal(career.totalWins, 0);
    assert.equal(career.totalPlaytimeFrames, 0);
  });

  it("fighter stats start at zero", () => {
    const fs = createDefaultFighterStats({
      fighterId: "f1",
      fighterName: "Blaze",
      size: "medium",
      color: "red",
      elementName: "Fire",
    });
    assert.equal(fs.matchesPlayed, 0);
    assert.equal(fs.kos, 0);
    assert.equal(fs.derbyBestDistance, 0);
  });

  it("win rate and accuracy helpers", () => {
    assert.equal(computeWinRate(3, 1), 75);
    assert.equal(computeHitAccuracy(8, 2), 80);
    assert.equal(computeWinRate(0, 0), 0);
  });

  it("match record updates career totals", () => {
    const career = createDefaultCareerProfile();
    const fighter = getDefaultCreatedFighter(0);
    const fs = createDefaultFighterStats({
      fighterId: fighter.id,
      fighterName: fighter.name,
      size: fighter.size,
      color: fighter.color,
      elementName: "Fire",
    });

    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 42);
    const initial = createInitialGameState(config);
    const final = createInitialGameState(config);
    final.frame = 3600;
    final.winnerId = 0;
    final.phase = "results";

    const events: StatEvent[] = [
      { type: "matchStarted", frame: 0, mode: "playMatch" },
      { type: "damage", frame: 100, attackerPlayerId: 0, victimPlayerId: 1, amount: 25 },
      { type: "ko", frame: 200, attackerPlayerId: 0, victimPlayerId: 1 },
      { type: "matchEnded", frame: 3600, winnerPlayerId: 0 },
    ];

    const match = buildMatchRecordFromEvents({
      initialState: initial,
      finalState: final,
      events,
      playerMetas: [
        {
          playerId: 0,
          playerName: "P1",
          fighterId: fighter.id,
          fighterName: fighter.name,
          isBot: false,
          size: fighter.size,
          color: fighter.color,
          elementName: "Fire",
        },
        {
          playerId: 1,
          playerName: "P2",
          fighterId: fighter.id,
          fighterName: fighter.name,
          isBot: false,
          size: fighter.size,
          color: fighter.color,
          elementName: "Fire",
        },
      ],
    });
    const result = applyMatchRecordToCareer(career, [fs], match, 0);

    assert.equal(result.career.totalMatches, 1);
    assert.equal(result.career.totalWins, 1);
    assert.equal(result.career.totalKOs, 1);
    assert.equal(result.career.totalDamageDealt, 25);
    const updated = result.fighterStats.find((f) => f.fighterId === fighter.id);
    assert.equal(updated?.wins, 1);
    assert.equal(updated?.kos, 1);
  });

  it("derby best distance updates only when better", () => {
    const career = createDefaultCareerProfile();
    const fighter = getDefaultCreatedFighter(0);
    const fs = createDefaultFighterStats({
      fighterId: fighter.id,
      fighterName: fighter.name,
      size: fighter.size,
      color: fighter.color,
      elementName: "Fire",
    });
    fs.derbyBestDistance = 500;

    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 1);
    const initial = createInitialGameState(config);
    const final = createInitialGameState(config);
    final.frame = 600;

    const worse = buildMatchRecordFromEvents({
      initialState: initial,
      finalState: final,
      events: [
        { type: "matchStarted", frame: 0, mode: "impactDummyDerby" },
        { type: "derbyLaunched", frame: 500, playerId: 0, distance: 400, score: 100, launchSpeed: 50 },
        { type: "matchEnded", frame: 600 },
      ],
      playerMetas: [
        {
          playerId: 0,
          playerName: "P1",
          fighterId: fighter.id,
          fighterName: fighter.name,
          isBot: false,
          size: fighter.size,
          color: fighter.color,
          elementName: "Fire",
        },
      ],
    });
    let result = applyMatchRecordToCareer(career, [fs], worse, 0);
    assert.equal(result.fighterStats[0].derbyBestDistance, 500);

    const better = buildMatchRecordFromEvents({
      initialState: initial,
      finalState: final,
      events: [
        { type: "matchStarted", frame: 0, mode: "impactDummyDerby" },
        { type: "derbyLaunched", frame: 500, playerId: 0, distance: 800, score: 200, launchSpeed: 90 },
        { type: "matchEnded", frame: 600 },
      ],
      playerMetas: [
        {
          playerId: 0,
          playerName: "P1",
          fighterId: fighter.id,
          fighterName: fighter.name,
          isBot: false,
          size: fighter.size,
          color: fighter.color,
          elementName: "Fire",
        },
      ],
    });
    result = applyMatchRecordToCareer(result.career, result.fighterStats, better, 0);
    assert.equal(result.fighterStats[0].derbyBestDistance, 800);
    assert.equal(result.fighterStats[0].derbyBestScore, 200);
  });

  it("flagline captures update fighter stats", () => {
    const career = createDefaultCareerProfile();
    const fighter = getDefaultCreatedFighter(0);
    const fs = createDefaultFighterStats({
      fighterId: fighter.id,
      fighterName: fighter.name,
      size: fighter.size,
      color: fighter.color,
      elementName: "Fire",
    });

    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 7);
    const initial = createInitialGameState(config);
    const final = createInitialGameState(config);
    final.frame = 1200;

    const match = buildMatchRecordFromEvents({
      initialState: initial,
      finalState: final,
      events: [
        { type: "matchStarted", frame: 0, mode: "flaglineClash" },
        { type: "flaglineCoreCaptured", frame: 400, teamId: "solar", playerIds: [0] },
        { type: "flaglineRoomWon", frame: 500, teamId: "solar", roomIndex: 0 },
        { type: "matchEnded", frame: 1200, winningTeam: "solar" },
      ],
      playerMetas: [
        {
          playerId: 0,
          playerName: "P1",
          fighterId: fighter.id,
          fighterName: fighter.name,
          teamId: "solar",
          isBot: false,
          size: fighter.size,
          color: fighter.color,
          elementName: "Fire",
        },
      ],
    });

    const result = applyMatchRecordToCareer(career, [fs], match, 0);
    assert.equal(result.fighterStats[0].flaglineCoresCaptured, 1);
    assert.equal(result.fighterStats[0].flaglineRoomsWon, 1);
  });
});
