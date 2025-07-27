import yfinance as yf
import pandas as pd
from typing import cast


def get_nasdaq_symbols(limit: int = 500) -> list:
    """
    Fetches the list of all NASDAQ-traded symbols and returns a slice of it.
    """
    try:
        url = "http://www.nasdaqtrader.com/dynamic/SymDir/nasdaqtraded.txt"
        df = pd.read_csv(url, sep="|")

        valid_symbols = df[(df["Test Issue"] == "N") & (df["ETF"] == "N")]

        symbols = valid_symbols["Symbol"].tolist()
        print(f"✅ Successfully fetched {len(symbols)} total NASDAQ symbols.")
        return symbols[:limit]

    except Exception as e:
        print(f"❌ Error fetching NASDAQ symbols: {e}")
        return [
            "AAPL",
            "MSFT",
            "GOOGL",
            "AMZN",
            "META",
            "TSLA",
            "JPM",
            "JNJ",
            "V",
            "WMT",
        ][:limit]


def download_data_batch(tickers: list, period: str = "5y"):
    """
    Downloads historical price data for a list of tickers in a single batch.
    """
    print(f"\nDownloading data for {len(tickers)} tickers for period '{period}'...")

    data = yf.download(
        tickers,
        period=period,
        auto_adjust=True,
        group_by="ticker",
        threads=True,
    )

    if not isinstance(data, pd.DataFrame) or data.empty:
        print("Could not download any data.")
        return None

    intermediate_series = data.stack(level=0)["Close"]

    close_prices = cast(pd.Series, intermediate_series).unstack()

    successful_downloads = close_prices.shape[1]
    print(
        f"Successfully downloaded data for {successful_downloads} of {len(tickers)} tickers."
    )

    return close_prices


def main():
    """Main function to run the data download and save process."""

    NUM_SYMBOLS_TO_DOWNLOAD = 500
    PERIOD = "5y"
    OUTPUT_FILENAME = "nasdaq_" + cast(str, NUM_SYMBOLS_TO_DOWNLOAD) + "_prices.csv"

    symbols = get_nasdaq_symbols(limit=NUM_SYMBOLS_TO_DOWNLOAD)

    price_data = download_data_batch(symbols, period=PERIOD)

    if price_data is not None and not price_data.empty:
        price_data.to_csv(OUTPUT_FILENAME)
        print(f"\n✅ Data saved to '{OUTPUT_FILENAME}'")
        print(
            f"Final dataset contains {price_data.shape[0]} rows and {price_data.shape[1]} columns."
        )
    else:
        print("\nNo data was saved.")


if __name__ == "__main__":
    main()
