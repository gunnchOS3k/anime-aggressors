#include "aa/simulation.hpp"

#include <cassert>
#include <iostream>

int main() {
  aa::GameConfig config;
  config.player_count = 2;
  config.stocks = 3;

  auto state = aa::create_initial_state(config);
  const std::string h0 = aa::hash_state(state);

  std::vector<aa::InputFrame> inputs;
  aa::InputFrame move;
  move.frame = 1;
  move.player_id = 0;
  move.right = true;
  inputs.push_back(move);

  state = aa::simulate_frame(state, inputs);
  const std::string h1 = aa::hash_state(state);

  assert(h0 != h1);

  auto state2 = aa::create_initial_state(config);
  state2 = aa::simulate_frame(state2, inputs);
  assert(aa::hash_state(state2) == h1);

  std::cout << "native determinism ok hash=" << h1 << std::endl;
  return 0;
}
