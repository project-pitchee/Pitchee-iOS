#include "internal.hpp"

#include <algorithm>
#include <iomanip>
#include <iostream>

// Use the real Core implementation as an independent oracle. Reflect pitch
// around the midpoint of its 110...200 Hz reference and complement VFP.
int main() {
    std::cout << std::setprecision(17);
    for (double feminine : {-10.0, 0.0, 20.0, 49.999, 50.0, 50.001, 80.0, 100.0, 110.0}) {
        for (double naturalness : {-10.0, 0.0, 40.0, 49.999, 50.0, 80.0, 80.001, 90.0, 100.0, 110.0}) {
            for (double pitch : {0.0, 40.0, 85.0, 110.0, 119.999, 120.0, 120.001,
                                 144.999, 145.0, 145.001, 155.0, 165.0, 199.999,
                                 200.0, 250.0, 310.0, 400.0}) {
                // Beyond the mirrored range, keep Core's pitch valid so its
                // existing zero-ratio branch applies instead of missing F0.
                const auto score = pitchee::calculate_composite_score(
                    100.0 - feminine, naturalness, pitch > 0.0,
                    std::max(1.0, 310.0 - pitch));
                std::cout << feminine << '\t' << naturalness << '\t' << pitch << '\t'
                          << score.base_score << '\t' << score.final_score << '\t'
                          << (score.has_score_cap ? score.score_cap : -1.0) << '\t'
                          << score.score_limited << '\t' << score.score_boosted << '\t'
                          << score.score_rule << '\n';
            }
        }
    }
}
