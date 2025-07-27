#ifndef PORTFOLIO_OPTIMZER_ASSET_HPP
#define PORTFOLIO_OPTIMZER_ASSET_HPP

#include <ctime>
#include <map>
#include <mutex>
#include <portfolio_optimizer/portfolio_lib_export.hpp>
#include <string>
#include <vector>


class PORTFOLIO_LIB_EXPORT Asset
{
private:
  std::string symbol_;

  std::map<std::time_t, double> historicalData_;

  mutable std::vector<double> dailyReturns_;

  mutable std::once_flag returnsCalculatedFlag_;

  void CalculateReturnsInternal() const;

public:
  explicit Asset(std::string symbol) : symbol_{ std::move(symbol) } {}

  void AddPrice(std::time_t date, double price);

  const std::string &GetSymbol() const { return symbol_; }

  const std::map<std::time_t, double> &GetPrices() const { return historicalData_; }

  const std::vector<double> &GetDailyReturns() const;
};


#endif
