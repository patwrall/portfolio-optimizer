#include <ctime>
#include <map>
#include <portfolio_optimizer/asset.hpp>
#include <stdexcept>

void Asset::AddPrice(std::time_t date, double price) { historical_data_.insert({ date, price }); }


const std::vector<double> &Asset::GetDailyReturns() const
{
  if (!returns_calculated_) { CalculateReturnsInternal(); }

  return daily_returns_;
}

void Asset::CalculateReturnsInternal() const
{
  if (historical_data_.size() < 2) {
    daily_returns_.clear();
    returns_calculated_ = true;
    return;
  }

  daily_returns_.reserve(historical_data_.size() - 1);

  auto itr = historical_data_.begin();
  auto prev_itr = itr;
  ++itr;

  for (; itr != historical_data_.end(); ++itr, ++prev_itr) {
    const double prev_price = prev_itr->second;
    const double curr_price = itr->second;

    if (prev_price == 0.0) {
      throw std::runtime_error("Error: Previous price is zero, cannot calculate return for asset " + symbol_);
    }

    const double daily_return = (curr_price - prev_price) / prev_price;
    daily_returns_.push_back(daily_return);
  }

  returns_calculated_ = true;
}
