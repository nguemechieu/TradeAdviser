//#############################################################################################################################
#property description "BinanceApiLibrary.mqh"
#property version "108.120"
#property copyright "Copyright 2021, Trading Clubs Corporation"
#property link "https://tradingclubs.com"
#property strict

//#############################################################################################################################
//enums
//#############################################################################################################################
enum ExchangeInfoKey 
{
   ExchangeInfo_timezone, 
   ExchangeInfo_serverTime, 
   ExchangeInfo_rateLimits, 
   ExchangeInfo_symbol
};

enum ExchangeInfoRatesLimitsKey 
{
   ExchangeInfoRatesLimits_rateLimitType, 
   ExchangeInfoRatesLimits_interval, 
   ExchangeInfoRatesLimits_intervalNum, 
   ExchangeInfoRatesLimits_limit
};

enum ExchangeInfoSymbolKey 
{
   ExchangeInfoSymbol_symbol, 
   ExchangeInfoSymbol_status, 
   ExchangeInfoSymbol_baseAsset, 
   ExchangeInfoSymbol_baseAssetPrecision, 
   ExchangeInfoSymbol_quoteAsset, 
   ExchangeInfoSymbol_quotePrecision, 
   ExchangeInfoSymbol_quoteAssetPrecision, 
   ExchangeInfoSymbol_orderTypes, 
   ExchangeInfoSymbol_icebergAllowed, 
   ExchangeInfoSymbol_ocoAllowed, 
   ExchangeInfoSymbol_isSpotTradingAllowed, 
   ExchangeInfoSymbol_isMarginTradingAllowed, 
   ExchangeInfoSymbol_filters, 
   ExchangeInfoSymbol_permissions
};

enum ExchangeInfoSymbolFiltersKey 
{
   ExchangeInfoSymbolFilters_PRICE_FILTER_minPrice, 
   ExchangeInfoSymbolFilters_PRICE_FILTER_maxPrice, 
   ExchangeInfoSymbolFilters_PRICE_FILTER_tickSize, 
   ExchangeInfoSymbolFilters_PERCENT_PRICE_multiplierUp, 
   ExchangeInfoSymbolFilters_PERCENT_PRICE_multiplierDown, 
   ExchangeInfoSymbolFilters_PERCENT_PRICE_avgPriceMins, 
   ExchangeInfoSymbolFilters_LOT_SIZE_minQty, 
   ExchangeInfoSymbolFilters_LOT_SIZE_maxQty, 
   ExchangeInfoSymbolFilters_LOT_SIZE_stepSize, 
   ExchangeInfoSymbolFilters_MIN_NOTIONAL_minNotional, 
   ExchangeInfoSymbolFilters_MIN_NOTIONAL_applyToMarket, 
   ExchangeInfoSymbolFilters_MIN_NOTIONAL_avgPriceMins, 
   ExchangeInfoSymbolFilters_ICEBERG_PARTS_limit, 
   ExchangeInfoSymbolFilters_MARKET_LOT_SIZE_minQty, 
   ExchangeInfoSymbolFilters_MARKET_LOT_SIZE_maxQty, 
   ExchangeInfoSymbolFilters_MARKET_LOT_SIZE_stepSize, 
   ExchangeInfoSymbolFilters_MAX_NUM_ORDERS_maxNumOrders, 
   ExchangeInfoSymbolFilters_MAX_NUM_ALGO_ORDERS_maxNumAlgoOrders
};

enum OrderBookKey 
{
   OrderBook_lastUpdateId, 
   OrderBook_bids, 
   OrderBook_asks
};

enum OrderBookBidsAsksValue 
{
   OrderBookBidsAsks_PRICE, 
   OrderBookBidsAsks_QTY
};

enum RecentTradesListKey 
{
   RecentTradesList_id, 
   RecentTradesList_price, 
   RecentTradesList_qty, 
   RecentTradesList_quoteQty, 
   RecentTradesList_time, 
   RecentTradesList_isBuyerMaker, 
   RecentTradesList_isBestMatch
};

enum KlinesDataInterval 
{
   KlinesInterval_1m, 
   KlinesInterval_3m, 
   KlinesInterval_5m, 
   KlinesInterval_15m, 
   KlinesInterval_30m, 
   KlinesInterval_1h, 
   KlinesInterval_2h, 
   KlinesInterval_4h, 
   KlinesInterval_6h, 
   KlinesInterval_8h, 
   KlinesInterval_12h, 
   KlinesInterval_1d, 
   KlinesInterval_3d, 
   KlinesInterval_1w, 
   KlinesInterval_1M
};

enum KlinesDataValue 
{
   KlinesData_OpenTime, 
   KlinesData_Open, 
   KlinesData_High, 
   KlinesData_Low, 
   KlinesData_Close, 
   KlinesData_Volume, 
   KlinesData_CloseTime, 
   KlinesData_QuoteAssetVolume, 
   KlinesData_NumberOfTrades, 
   KlinesData_TakerBuyBaseAssetVolume, 
   KlinesData_TakerBuyQuoteAssetVolume, 
   KlinesData_Ignore
};

enum CurrentAveragePriceKey 
{
   CurrentAveragePrice_mins, 
   CurrentAveragePrice_price
};

enum Ticker24HrKey 
{
   Ticker24Hr_symbol, 
   Ticker24Hr_priceChange, 
   Ticker24Hr_priceChangePercent, 
   Ticker24Hr_weightedAvgPrice, 
   Ticker24Hr_prevClosePrice, 
   Ticker24Hr_lastPrice, 
   Ticker24Hr_lastQty, 
   Ticker24Hr_bidPrice, 
   Ticker24Hr_askPrice, 
   Ticker24Hr_openPrice, 
   Ticker24Hr_highPrice, 
   Ticker24Hr_lowPrice, 
   Ticker24Hr_volume, 
   Ticker24Hr_quoteVolume, 
   Ticker24Hr_openTime, 
   Ticker24Hr_closeTime, 
   Ticker24Hr_firstId, 
   Ticker24Hr_lastId, 
   Ticker24Hr_count
};

enum SymbolPriceTickerKey 
{
   SymbolPriceTicker_symbol, 
   SymbolPriceTicker_price
};

enum SymbolOrderBookTickerKey 
{
   SymbolOrderBookTicker_symbol, 
   SymbolOrderBookTicker_bidPrice, 
   SymbolOrderBookTicker_bidQty, 
   SymbolOrderBookTicker_askPrice, 
   SymbolOrderBookTicker_askQty
};

enum OrderSide 
{
   OrderSide_BUY, 
   OrderSide_SELL
};

enum OrderType 
{
   OrderType_LIMIT, 
   OrderType_MARKET, 
   OOrderType_STOP_LOSS, 
   OrderType_STOP_LOSS_LIMIT, 
   OrderType_TAKE_PROFIT, 
   OrderType_TAKE_PROFIT_LIMIT, 
   OrderType_LIMIT_MAKER
};

enum TimeInForce 
{
   TimeInForce_GTC,
   TimeInForce_IOC, 
   TimeInForce_FOK
};

enum OrderResponseType 
{
   OrderResponce_ACK, 
   OrderResponce_RESULT, 
   OrderResponce_FULL
};

enum OrderResponseKey 
{
   OrderResponse_symbol, 
   OrderResponse_orderId, 
   OrderResponse_orderListId, 
   OrderResponse_clientOrderId, 
   OrderResponse_price, 
   OrderResponse_origQty, 
   OrderResponse_executedQty, 
   OrderResponse_cummulativeQuoteQty, 
   OrderResponse_status, 
   OrderResponse_timeInForce, 
   OrderResponse_type, 
   OrderResponse_side, 
   OrderResponse_stopPrice, 
   OrderResponse_icebergQty, 
   OrderResponse_time, 
   OrderResponse_updateTime, 
   OrderResponse_isWorking, 
   OrderResponse_origQuoteOrderQty
};

enum AccountInfoKey 
{
   AccountInfo_makerCommission, 
   AccountInfo_takerCommission, 
   AccountInfo_buyerCommission, 
   AccountInfo_sellerCommission, 
   AccountInfo_canTrade, 
   AccountInfo_canWithdraw, 
   AccountInfo_canDeposit, 
   AccountInfo_updateTime, 
   AccountInfo_accountType, 
   AccountInfo_balances, 
   AccountInfo_permissions
};

enum AccountInfoBalancesKey 
{
   AccountInfoBalance_asset, 
   AccountInfoBalance_free, 
   AccountInfoBalance_locked
};

enum AccountTradeListKey 
{
   AccountTradeList_symbol, 
   AccountTradeList_id, 
   AccountTradeList_orderId, 
   AccountTradeList_orderListId, 
   AccountTradeList_price, 
   AccountTradeList_qty, 
   AccountTradeList_quoteQty, 
   AccountTradeList_commission, 
   AccountTradeList_commissionAsset, 
   AccountTradeList_time, 
   AccountTradeList_isBuyer, 
   AccountTradeList_isMaker, 
   AccountTradeList_isBestMatch
};

//#############################################################################################################################
//imported functions
//#############################################################################################################################
#import "BinanceApiLibrary.ex4"
   //JSON functions
   string   _JsonGetKeyValue(string jsonString, string jsonKey);
   string   _JsonGetArrayValue(string jsonString, int jsonArrayIndex);
   int      _JsonGetArrayValuesTotal(string jsonString);
   //Binance API functions
   //Market Data Endpoints functions
   string   _TestConnectivity();
   string   _CheckServerTime();
   string   _ExchangeInformation(string symbol = NULL);
   string   _ExchangeInformation(ExchangeInfoKey exchangeInfoKey, string symbol = NULL);
   string   _ExchangeInformationRatesLimits(string symbol = NULL);
   string   _ExchangeInformationRatesLimits(int exchangeInfoRatesLimitsArrayIndex, string symbol = NULL);
   string   _ExchangeInformationRatesLimits(int exchangeInfoRatesLimitsArrayIndex, ExchangeInfoRatesLimitsKey exchangeInfoRatesLimitsKey, string symbol = NULL);
   string   _ExchangeInformationRatesLimits(string exchangeInfoRatesLimitsJsonString, int exchangeInfoRatesLimitsArrayIndex, ExchangeInfoRatesLimitsKey exchangeInfoRatesLimitsKey);
   int      _ExchangeInformationRatesLimitsTotal(string symbol = NULL);
   string   _ExchangeInformationSymbol(ExchangeInfoSymbolKey exchangeInfoSymbolKey, string symbol);
   string   _ExchangeInformationSymbolFilters(ExchangeInfoSymbolFiltersKey exchangeInfoSymbolFiltersKey, string symbol);
   string   _OrderBook(string symbol, int limit = -1);
   string   _OrderBook(OrderBookKey orderBookKey, string symbol, int limit = -1);
   string   _OrderBookBids(string symbol, int limit = -1);
   string   _OrderBookBids(int orderBookBidsAsksArrayIndex, string symbol, int limit = -1);
   string   _OrderBookBids(int orderBookBidsAsksArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue, string symbol, int limit = -1);
   string   _OrderBookBids(string orderBookBidsJsonString, int orderBookBidsArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue);
   int      _OrderBookBidsTotal(string symbol, int limit = -1);
   string   _OrderBookAsks(string symbol, int limit = -1);
   string   _OrderBookAsks(int orderBookBidsArrayIndex, string symbol, int limit = -1);
   string   _OrderBookAsks(int orderBookAsksArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue, string symbol, int limit = -1);
   string   _OrderBookAsks(string orderBookAsksJsonString, int orderBookAsksArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue);
   int      _OrderBookAsksTotal(string symbol, int limit = -1);
   string   _RecentTradesList(string symbol, int limit = -1);
   string   _RecentTradesList(int recentTradesListArrayIndex, string symbol);
   string   _RecentTradesList(int recentTradesListArrayIndex, RecentTradesListKey recentTradesListKey, string symbol);
   string   _RecentTradesList(string recentTradesListJsonString, int recentTradesListArrayIndex, RecentTradesListKey recentTradesListKey);
   int      _RecentTradesListTotal(string symbol, int limit = -1);
   string   _KlinesData(string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _KlinesData(int klinesDataArrayIndex, string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _KlinesData(int klinesDataArrayIndex, KlinesDataValue klinesDataValue, string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _KlinesData(string klinesDataJsonString, int klinesDataArrayIndex, KlinesDataValue klinesDataValue);
   int      _KlinesDataTotal(string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _CurrentAveragePrice(string symbol);
   string   _CurrentAveragePrice(CurrentAveragePriceKey currentAveragePriceKey, string symbol);
   string   _Ticker24HrPriceChangeStatistics(string symbol);
   string   _Ticker24HrPriceChangeStatistics(Ticker24HrKey ticker24HrKey, string symbol);
   string   _SymbolPriceTicker(string symbol);
   string   _SymbolPriceTicker(SymbolPriceTickerKey symbolPriceTickerKey, string symbol);
   string   _SymbolOrderBookTicker(string symbol);
   string   _SymbolOrderBookTicker(SymbolOrderBookTickerKey symbolOrderBookTickerKey, string symbol);
   //Spot Account/Trade functions
   string   _TestNewOrder(string apiKey, string apiSecret, string symbol, OrderSide side, OrderType type, TimeInForce timeInForce, double quantity = 0.0, double quoteOrderQty = 0.0, double price = 0.0, string newClientOrderId = NULL, double stopPrice = 0.0, double icebergQty = 0.0, OrderResponseType newOrderRespType = WRONG_VALUE);
   string   _NewOrder(string apiKey, string apiSecret, string symbol, OrderSide side, OrderType type, TimeInForce timeInForce, double quantity = 0.0, double quoteOrderQty = 0.0, double price = 0.0, string newClientOrderId = NULL, double stopPrice = 0.0, double icebergQty = 0.0, OrderResponseType newOrderRespType = WRONG_VALUE);
   string   _CancelOrder(string apiKey, string apiSecret, string symbol, long orderId = -1, string origClientOrderId = NULL, string newClientOrderId = NULL);
   string   _CancelAllOpenOrdersOnSymbol(string apiKey, string apiSecret, string symbol);
   string   _QueryOrder(string apiKey, string apiSecret, string symbol, long orderId = -1, string origClientOrderId = NULL);
   string   _QueryOrder(OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol, long orderId = -1, string origClientOrderId = NULL);
   string   _CurrentOpenOrders(string apiKey, string apiSecret, string symbol = NULL);
   string   _CurrentOpenOrders(int currentOpenOrdersArrayIndex, string apiKey, string apiSecret, string symbol = NULL);
   string   _CurrentOpenOrders(int currentOpenOrdersArrayIndex, OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol = NULL);
   string   _CurrentOpenOrders(string currentOpenOrdersJsonString, int currentOpenOrdersArrayIndex, OrderResponseKey orderResponseKey);
   int      _CurrentOpenOrdersTotal(string apiKey, string apiSecret, string symbol = NULL);
   string   _AllOrders(string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _AllOrders(int allOrdersArrayIndex, string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _AllOrders(int allOrdersArrayIndex, OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _AllOrders(string allOrdersJsonString, int allOrdersArrayIndex, OrderResponseKey orderResponseKey);
   int      _AllOrdersTotal(int allOrdersArrayIndex, OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1);
   string   _AccountInformation(string apiKey, string apiSecret);
   string   _AccountInformation(AccountInfoKey accountInfoKey, string apiKey, string apiSecret);
   string   _AccountInformationBalances(string apiKey, string apiSecret);
   string   _AccountInformationBalances(int accountInfoBalancesArrayIndex, string apiKey, string apiSecret);
   string   _AccountInformationBalances(int accountInfoBalancesArrayIndex, AccountInfoBalancesKey accountInfoBalancesKey, string apiKey, string apiSecret);
   string   _AccountInformationBalances(string accountInfoBalancesJsonString, int accountInfoBalancesArrayIndex, AccountInfoBalancesKey accountInfoBalancesKey);
   int      _AccountInformationBalancesTotal(string apiKey, string apiSecret);
   string   _AccountTradeList(string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1);
   string   _AccountTradeList(int accountTradeListArrayIndex, string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1);
   string   _AccountTradeList(int accountTradeListArrayIndex, AccountTradeListKey accountTradeListKey, string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1);
   int      _AccountTradeListTotal(string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1);
#import

//#############################################################################################################################
//class BinanceApi
//#############################################################################################################################
class BinanceApi
{
   public:
      //JSON functions
      string   JsonGetKeyValue(string jsonString, string jsonKey) {return (_JsonGetKeyValue(jsonString, jsonKey));}
      string   JsonGetArrayValue(string jsonString, int jsonArrayIndex) {return (_JsonGetArrayValue(jsonString, jsonArrayIndex));}
      int      JsonGetArrayValuesTotal(string jsonString) {return (_JsonGetArrayValuesTotal(jsonString));}
      //Binance API functions
      //Market Data Endpoints functions
      string   TestConnectivity() {return (_TestConnectivity());}
      string   CheckServerTime() {return (_CheckServerTime());}
      string   ExchangeInformation(string symbol = NULL) {return (_ExchangeInformation(symbol));}
      string   ExchangeInformation(ExchangeInfoKey exchangeInfoKey, string symbol = NULL) {return (_ExchangeInformation(exchangeInfoKey, symbol));}
      string   ExchangeInformationRatesLimits(string symbol = NULL) {return (_ExchangeInformationRatesLimits(symbol));}
      string   ExchangeInformationRatesLimits(int exchangeInfoRatesLimitsArrayIndex, string symbol = NULL) {return (_ExchangeInformationRatesLimits(exchangeInfoRatesLimitsArrayIndex, symbol));}
      string   ExchangeInformationRatesLimits(int exchangeInfoRatesLimitsArrayIndex, ExchangeInfoRatesLimitsKey exchangeInfoRatesLimitsKey, string symbol = NULL) {return (_ExchangeInformationRatesLimits(exchangeInfoRatesLimitsArrayIndex, exchangeInfoRatesLimitsKey, symbol));}
      string   ExchangeInformationRatesLimits(string exchangeInfoRatesLimitsJsonString, int exchangeInfoRatesLimitsArrayIndex, ExchangeInfoRatesLimitsKey exchangeInfoRatesLimitsKey) {return (_ExchangeInformationRatesLimits(exchangeInfoRatesLimitsJsonString, exchangeInfoRatesLimitsArrayIndex, exchangeInfoRatesLimitsKey));}
      int      ExchangeInformationRatesLimitsTotal(string symbol = NULL) {return (_ExchangeInformationRatesLimitsTotal(symbol));}
      string   ExchangeInformationSymbol(ExchangeInfoSymbolKey exchangeInfoSymbolKey, string symbol) {return (_ExchangeInformationSymbol(exchangeInfoSymbolKey, symbol));}
      string   ExchangeInformationSymbolFilters(ExchangeInfoSymbolFiltersKey exchangeInfoSymbolFiltersKey, string symbol) {return (_ExchangeInformationSymbolFilters(exchangeInfoSymbolFiltersKey, symbol));}
      string   OrderBook(string symbol, int limit = -1) {return (_OrderBook(symbol, limit));}
      string   OrderBook(OrderBookKey orderBookKey, string symbol, int limit = -1) {return (_OrderBook(orderBookKey, symbol, limit));}
      string   OrderBookBids(string symbol, int limit = -1) {return (_OrderBookBids(symbol, limit));}
      string   OrderBookBids(int orderBookBidsAsksArrayIndex, string symbol, int limit = -1) {return (_OrderBookBids(orderBookBidsAsksArrayIndex, symbol, limit));}
      string   OrderBookBids(int orderBookBidsAsksArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue, string symbol, int limit = -1) {return (_OrderBookBids(orderBookBidsAsksArrayIndex, orderBookBidsAsksValue, symbol, limit));}
      string   OrderBookBids(string orderBookBidsJsonString, int orderBookBidsArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue) {return (_OrderBookBids(orderBookBidsJsonString, orderBookBidsArrayIndex, orderBookBidsAsksValue));}
      int      OrderBookBidsTotal(string symbol, int limit = -1) {return (_OrderBookBidsTotal(symbol, limit));}
      string   OrderBookAsks(string symbol, int limit = -1) {return (_OrderBookAsks(symbol, limit));}
      string   OrderBookAsks(int orderBookBidsArrayIndex, string symbol, int limit = -1) {return (_OrderBookAsks(orderBookBidsArrayIndex, symbol, limit));}
      string   OrderBookAsks(int orderBookAsksArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue, string symbol, int limit = -1) {return (_OrderBookAsks(orderBookAsksArrayIndex, orderBookBidsAsksValue, symbol, limit));}
      string   OrderBookAsks(string orderBookAsksJsonString, int orderBookAsksArrayIndex, OrderBookBidsAsksValue orderBookBidsAsksValue) {return (_OrderBookAsks(orderBookAsksJsonString, orderBookAsksArrayIndex, orderBookBidsAsksValue));}
      int      OrderBookAsksTotal(string symbol, int limit = -1) {return (_OrderBookAsksTotal(symbol, limit));}
      string   RecentTradesList(string symbol, int limit = -1) {return (_RecentTradesList(symbol, limit));}
      string   RecentTradesList(int recentTradesListArrayIndex, string symbol) {return (_RecentTradesList(recentTradesListArrayIndex, symbol));}
      string   RecentTradesList(int recentTradesListArrayIndex, RecentTradesListKey recentTradesListKey, string symbol) {return (_RecentTradesList(recentTradesListArrayIndex, recentTradesListKey, symbol));}
      string   RecentTradesList(string recentTradesListJsonString, int recentTradesListArrayIndex, RecentTradesListKey recentTradesListKey) {return (_RecentTradesList(recentTradesListJsonString, recentTradesListArrayIndex, recentTradesListKey));}
      int      RecentTradesListTotal(string symbol, int limit = -1) {return (_RecentTradesListTotal(symbol, limit));}
      string   KlinesData(string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_KlinesData(symbol, klinesDataInterval, startTime, endTime, limit));}
      string   KlinesData(int klinesDataArrayIndex, string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_KlinesData(klinesDataArrayIndex, symbol, klinesDataInterval, startTime, endTime, limit));}
      string   KlinesData(int klinesDataArrayIndex, KlinesDataValue klinesDataValue, string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_KlinesData(klinesDataArrayIndex, klinesDataValue, symbol, klinesDataInterval, startTime, endTime, limit));}
      string   KlinesData(string klinesDataJsonString, int klinesDataArrayIndex, KlinesDataValue klinesDataValue) {return (_KlinesData(klinesDataJsonString, klinesDataArrayIndex, klinesDataValue));}
      int      KlinesDataTotal(string symbol, KlinesDataInterval klinesDataInterval, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_KlinesDataTotal(symbol, klinesDataInterval, startTime, endTime, limit));}
      string   CurrentAveragePrice(string symbol) {return (_CurrentAveragePrice(symbol));}
      string   CurrentAveragePrice(CurrentAveragePriceKey currentAveragePriceKey, string symbol) {return (_CurrentAveragePrice(currentAveragePriceKey, symbol));}
      string   Ticker24HrPriceChangeStatistics(string symbol) {return (_Ticker24HrPriceChangeStatistics(symbol));}
      string   Ticker24HrPriceChangeStatistics(Ticker24HrKey ticker24HrKey, string symbol) {return (_Ticker24HrPriceChangeStatistics(ticker24HrKey, symbol));}
      string   SymbolPriceTicker(string symbol) {return (_SymbolPriceTicker(symbol));}
      string   SymbolPriceTicker(SymbolPriceTickerKey symbolPriceTickerKey, string symbol) {return (_SymbolPriceTicker(symbolPriceTickerKey, symbol));}
      string   SymbolOrderBookTicker(string symbol) {return (_SymbolOrderBookTicker(symbol));}
      string   SymbolOrderBookTicker(SymbolOrderBookTickerKey symbolOrderBookTickerKey, string symbol) {return (_SymbolOrderBookTicker(symbolOrderBookTickerKey, symbol));}
      //Spot Account/Trade functions
      string   TestNewOrder(string apiKey, string apiSecret, string symbol, OrderSide side, OrderType type, TimeInForce timeInForce, double quantity = 0.0, double quoteOrderQty = 0.0, double price = 0.0, string newClientOrderId = NULL, double stopPrice = 0.0, double icebergQty = 0.0, OrderResponseType newOrderRespType = WRONG_VALUE) {return (_TestNewOrder(apiKey, apiSecret, symbol, side, type, timeInForce, quantity, quoteOrderQty, price, newClientOrderId, stopPrice, icebergQty, newOrderRespType));}
      string   NewOrder(string apiKey, string apiSecret, string symbol, OrderSide side, OrderType type, TimeInForce timeInForce, double quantity = 0.0, double quoteOrderQty = 0.0, double price = 0.0, string newClientOrderId = NULL, double stopPrice = 0.0, double icebergQty = 0.0, OrderResponseType newOrderRespType = WRONG_VALUE) {return (_NewOrder(apiKey, apiSecret, symbol, side, type, timeInForce, quantity, quoteOrderQty, price, newClientOrderId, stopPrice, icebergQty, newOrderRespType));}
      string   CancelOrder(string apiKey, string apiSecret, string symbol, long orderId = -1, string origClientOrderId = NULL, string newClientOrderId = NULL) {return (_CancelOrder(apiKey, apiSecret, symbol, orderId, origClientOrderId, newClientOrderId));}
      string   CancelAllOpenOrdersOnSymbol(string apiKey, string apiSecret, string symbol) {return (_CancelAllOpenOrdersOnSymbol(apiKey, apiSecret, symbol));}
      string   QueryOrder(string apiKey, string apiSecret, string symbol, long orderId = -1, string origClientOrderId = NULL) {return (_QueryOrder(apiKey, apiSecret, symbol, orderId, origClientOrderId));}
      string   QueryOrder(OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol, long orderId = -1, string origClientOrderId = NULL) {return (_QueryOrder(orderResponseKey, apiKey, apiSecret, symbol, orderId, origClientOrderId));}
      string   CurrentOpenOrders(string apiKey, string apiSecret, string symbol = NULL) {return (_CurrentOpenOrders(apiKey, apiSecret, symbol));}
      string   CurrentOpenOrders(string currentOpenOrdersJsonString, int currentOpenOrdersArrayIndex, OrderResponseKey orderResponseKey) {return (_CurrentOpenOrders(currentOpenOrdersJsonString, currentOpenOrdersArrayIndex, orderResponseKey));}
      string   CurrentOpenOrders(int currentOpenOrdersArrayIndex, string apiKey, string apiSecret, string symbol = NULL) {return (_CurrentOpenOrders(currentOpenOrdersArrayIndex, apiKey, apiSecret, symbol));}
      string   CurrentOpenOrders(int currentOpenOrdersArrayIndex, OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol = NULL) {return (_CurrentOpenOrders(currentOpenOrdersArrayIndex, orderResponseKey, apiKey, apiSecret, symbol));}
      int      CurrentOpenOrdersTotal(string apiKey, string apiSecret, string symbol = NULL) {return (_CurrentOpenOrdersTotal(apiKey, apiSecret, symbol));}
      string   AllOrders(string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_AllOrders(apiKey, apiSecret, symbol, orderId, startTime, endTime, limit));}
      string   AllOrders(int allOrdersArrayIndex, string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_AllOrders(allOrdersArrayIndex, apiKey, apiSecret, symbol, orderId, startTime, endTime, limit));}
      string   AllOrders(int allOrdersArrayIndex, OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_AllOrders(allOrdersArrayIndex, orderResponseKey, apiKey, apiSecret, symbol, orderId, startTime, endTime, limit));}
      string   AllOrders(string allOrdersJsonString, int allOrdersArrayIndex, OrderResponseKey orderResponseKey) {return (_AllOrders(allOrdersJsonString, allOrdersArrayIndex, orderResponseKey));}
      int      AllOrdersTotal(int allOrdersArrayIndex, OrderResponseKey orderResponseKey, string apiKey, string apiSecret, string symbol, long orderId = -1, datetime startTime = -1, datetime endTime = -1, int limit = -1) {return (_AllOrdersTotal(allOrdersArrayIndex, orderResponseKey, apiKey, apiSecret, symbol, orderId, startTime, endTime, limit));}
      string   AccountInformation(string apiKey, string apiSecret) {return (_AccountInformation(apiKey, apiSecret));}
      string   AccountInformation(AccountInfoKey accountInfoKey, string apiKey, string apiSecret) {return (_AccountInformation(accountInfoKey, apiKey, apiSecret));}
      string   AccountInformationBalances(string apiKey, string apiSecret) {return (_AccountInformationBalances(apiKey, apiSecret));}
      string   AccountInformationBalances(int accountInfoBalancesArrayIndex, string apiKey, string apiSecret) {return (_AccountInformationBalances(accountInfoBalancesArrayIndex, apiKey, apiSecret));}
      string   AccountInformationBalances(int accountInfoBalancesArrayIndex, AccountInfoBalancesKey accountInfoBalancesKey, string apiKey, string apiSecret) {return (_AccountInformationBalances(accountInfoBalancesArrayIndex, accountInfoBalancesKey, apiKey, apiSecret));}
      string   AccountInformationBalances(string accountInfoBalancesJsonString, int accountInfoBalancesArrayIndex, AccountInfoBalancesKey accountInfoBalancesKey) {return (_AccountInformationBalances(accountInfoBalancesJsonString, accountInfoBalancesArrayIndex, accountInfoBalancesKey));}
      int      AccountInformationBalancesTotal(string apiKey, string apiSecret) {return (_AccountInformationBalancesTotal(apiKey, apiSecret));}
      string   AccountTradeList(string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1) {return (_AccountTradeList(apiKey, apiSecret, symbol, startTime, endTime, fromId, limit));}
      string   AccountTradeList(int accountTradeListArrayIndex, string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1) {return (_AccountTradeList(accountTradeListArrayIndex, apiKey, apiSecret, symbol, startTime, endTime, fromId, limit));}
      string   AccountTradeList(int accountTradeListArrayIndex, AccountTradeListKey accountTradeListKey, string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1) {return (_AccountTradeList(accountTradeListArrayIndex, accountTradeListKey, apiKey, apiSecret, symbol, startTime, endTime, fromId, limit));}
      int      AccountTradeListTotal(string apiKey, string apiSecret, string symbol, datetime startTime = -1, datetime endTime = -1, long fromId = -1, int limit = -1) {return (_AccountTradeListTotal(apiKey, apiSecret, symbol, startTime, endTime, fromId, limit));}
};

//#############################################################################################################################
