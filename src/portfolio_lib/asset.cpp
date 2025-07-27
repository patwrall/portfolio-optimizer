#include <ctime>
#include <map>
#include <mutex>
#include <portfolio_optimizer/asset.hpp>
#include <stdexcept>

void Asset::AddPrice(std::time_t date, double price) { historicalData_.insert({ date, price }); }


const std::vector<double> &Asset::GetDailyReturns() const
{
  std::call_once(returnsCalculatedFlag_, &Asset::CalculateReturnsInternal, this);

  return dailyReturns_;
}

void Asset::CalculateReturnsInternal() const
{
  if (historicalData_.size() < 2) {
    dailyReturns_.clear();
    return;
  }

  dailyReturns_.reserve(historicalData_.size() - 1);

  auto itr = historicalData_.begin();
  auto prev_itr = itr;
  ++itr;

  for (; itr != historicalData_.end(); ++itr, ++prev_itr) {
    const double prev_price = prev_itr->second;
    const double curr_price = itr->second;

    if (prev_price == 0.0) {
      throw std::runtime_error("Error: Previous price is zero, cannot calculate return for asset " + symbol_);
    }

    const double dailyReturn = (curr_price - prev_price) / prev_price;
    dailyReturns_.push_back(dailyReturn);
  }
}
