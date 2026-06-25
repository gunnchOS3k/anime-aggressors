#include "aa/simulation.hpp"

#include <sstream>

namespace aa {

namespace {
constexpr int GRAVITY = (12 * FP_SCALE) / SIM_HZ;
constexpr int RUN_SPEED = (6 * FP_SCALE) / SIM_HZ;
constexpr int JUMP_VELOCITY = -(14 * FP_SCALE) / SIM_HZ;
constexpr int FLOOR_Y = 900 * FP_SCALE;
}  // namespace

GameState create_initial_state(const GameConfig& config) {
  GameState state;
  state.frame = 0;
  state.players.reserve(static_cast<size_t>(config.player_count));

  for (int i = 0; i < config.player_count; ++i) {
    PlayerState p;
    p.id = i;
    p.x = (i == 0 ? 400 : 600) * FP_SCALE;
    p.y = FLOOR_Y - 64 * FP_SCALE;
    p.facing = i == 0 ? 1 : -1;
    p.stocks = config.stocks;
    state.players.push_back(p);
  }
  return state;
}

GameState simulate_frame(const GameState& state, const std::vector<InputFrame>& inputs) {
  GameState next = state;
  next.frame += 1;

  for (auto& player : next.players) {
    const InputFrame* input = nullptr;
    for (const auto& frame : inputs) {
      if (frame.player_id == player.id) {
        input = &frame;
        break;
      }
    }

    if (input) {
      if (input->left) {
        player.vx = -RUN_SPEED;
        player.facing = -1;
      } else if (input->right) {
        player.vx = RUN_SPEED;
        player.facing = 1;
      } else if (player.on_ground) {
        player.vx = 0;
      }

      if (input->jump && player.on_ground) {
        player.vy = JUMP_VELOCITY;
        player.on_ground = false;
      }
    }

    player.vy += GRAVITY;
    player.x += player.vx;
    player.y += player.vy;

    if (player.y >= FLOOR_Y) {
      player.y = FLOOR_Y;
      player.vy = 0;
      player.on_ground = true;
    } else {
      player.on_ground = false;
    }
  }

  return next;
}

std::string hash_state(const GameState& state) {
  std::ostringstream oss;
  oss << state.frame;
  for (const auto& p : state.players) {
    oss << '|' << p.id << ',' << p.x << ',' << p.y << ',' << p.vx << ',' << p.vy << ','
        << p.damage << ',' << p.stocks << ',' << p.facing;
  }

  const std::string payload = oss.str();
  uint32_t hash = 2166136261u;
  for (unsigned char c : payload) {
    hash ^= c;
    hash *= 16777619u;
  }

  std::ostringstream hex;
  hex << std::hex << hash;
  return hex.str();
}

}  // namespace aa
