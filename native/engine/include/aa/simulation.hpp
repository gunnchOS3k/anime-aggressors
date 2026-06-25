#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace aa {

constexpr int SIM_HZ = 60;
constexpr int FP_SCALE = 256;

struct InputFrame {
  int frame = 0;
  int player_id = 0;
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool jump = false;
  bool attack = false;
  bool special = false;
  bool shield = false;
  bool dodge = false;
  bool grab = false;
};

struct PlayerState {
  int id = 0;
  int x = 0;
  int y = 0;
  int vx = 0;
  int vy = 0;
  int facing = 1;
  int damage = 0;
  int stocks = 3;
  bool on_ground = true;
};

struct GameState {
  int frame = 0;
  std::vector<PlayerState> players;
};

struct GameConfig {
  int player_count = 2;
  int stocks = 3;
  int seed = 0;
};

GameState create_initial_state(const GameConfig& config);
GameState simulate_frame(const GameState& state, const std::vector<InputFrame>& inputs);
std::string hash_state(const GameState& state);

}  // namespace aa
