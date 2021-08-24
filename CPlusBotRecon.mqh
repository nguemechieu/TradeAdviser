//|-----------------------------------------------------------------------------------------|
//|                                                                       CPlusBotRecon.mq4 |
//|                                                              Copyright 2019, Dennis Lee |
//|                                   https://github.com/dennislwm/MT5-MT4-Telegram-API-Bot |
//|                                                                                         |
//| History                                                                                 |
//|   0.9.0    The CPlusBotRecon class inherits from CCustomBot. We added general, order    |
//|      status, history status, and account status bot commands:                           |
//|      (1) /help - Display a list of bot commands                                         |
//|      (2) /ordertotal - Return count of orders                                           |
//|      (3) /ordertrade - Return ALL orders, where EACH order includes ticket, symbol,     |
//|            type, lots, openprice, stoploss, takeprofit, opentime and prevticket.        |
//|            Note: curprice, swap, profit, expiration, closetime, magicno, accountno,     |
//|               and expertname are NOT returned.                                          |
//|      (4) /orderticket <ticket> - Return an order by ticket number. If <ticket> is a     |
//|            partial trade, return a chain of orders and history, otherwise return a      |
//|            single trade.                                                                |
//|      (5) /historytotal - Return count of history                                        |
//|      (6) /historyticket <ticket> - Return a history or a chain of history, where EACH   |
//|            history includes ticket, symbol, type, lots, openprice, closeprice, stoploss,|
//|            takeprofit, opentime, closetime, and prevticket.                             |
//|            Note: opentime, swap, profit, expiration, magicno, accountno, and            |
//|            expertname are NOT returned.                                                 |
//|      (7) /account - Return account number, currency, balance, equity, margin,           |
//|            freemargin and profit.                                                       |
//|-----------------------------------------------------------------------------------------|
#property copyright "Copyright 2020,nguemechieu@live.com "
#property link      "https://github.com/dennislwm/MT5-MT4-Telegram-API-Bot"
#property strict

//---- Assert Basic externs


//|-----------------------------------------------------------------------------------------|
//|                               M A I N   P R O C E D U R E                               |
//|-----------------------------------------------------------------------------------------|



class CPlusBotRecon: public CCustomBot
{


private:
   string            m_radio_button[3];
   int               m_radio_index;
   bool              m_lock_state;
   bool              m_mute_state;

public:
                   


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


   //+------------------------------------------------------------------+
 string GetKeyboard()
     {
      //---
      string radio_code[3]={RADIO_EMPTY,RADIO_EMPTY,RADIO_EMPTY};
      if(m_radio_index>=0 && m_radio_index<=2)
         radio_code[m_radio_index]=RADIO_SELECT;
      //---
      string mute_text=UNMUTE_TEXT;
      string mute_code=UNMUTE_CODE;
      if(m_mute_state)
        {
         mute_text=MUTE_TEXT;
         mute_code=MUTE_CODE;
        }
      //---
      string lock_text=UNLOCK_TEXT;
      string lock_code=UNLOCK_CODE;
      if(m_lock_state)
        {
         lock_text=LOCK_TEXT;
         lock_code=LOCK_CODE;
        }
      //---
      //Print(m_lock.GetKey());
      return(StringFormat("[[\"%s %s\"],[\"%s %s\"],[\"%s %s\"],[\"%s %s\",\"%s %s\"]]",
             radio_code[0],m_radio_button[0],
             radio_code[1],m_radio_button[1],
             radio_code[2],m_radio_button[2],
             lock_code,lock_text,
             mute_code,mute_text));
     }


 virtual  void ProcessMessages(void)
   {  m_radio_button[0]="Radio Button #1";
      m_radio_button[1]="Radio Button #2";
      m_radio_button[2]="Radio Button #3";
      m_radio_index=0;
      m_lock_state=false;
      m_mute_state=true;
      string msg=NL;
      const string strOrderTrade="/ordertrade";
      const string strHistoryTicket="/historyticket";
      int pos=0, ticket=0;
      for( int i=0; i<m_chats.Total(); i++ ) {
         CCustomChat *chat=m_chats.GetNodeAtIndex(i);
         
         if( !chat.m_new_one.done ) {
            chat.m_new_one.done=true;
            
            string text=chat.m_new_one.message_text;
            
            if( text=="/ordertotal" ) {
               SendMessage( chat.m_id, BotOrdersTotal() );
            }
            
            if( StringFind( text, strOrderTrade )>=0 ) {
               pos= (int)StringToInteger( StringSubstr( text, StringLen(strOrderTrade)+1 ) );
               SendMessage( chat.m_id, BotOrdersTrade(pos) );
            }

            if( text=="/historytotal" ) {
               SendMessage( chat.m_id, BotOrdersHistoryTotal() );
            }

            if( StringFind( text, strHistoryTicket )>=0 ) {
               ticket = (int)StringToInteger( StringSubstr( text, StringLen(strHistoryTicket)+1 ) );
               SendMessage( chat.m_id, BotHistoryTicket(ticket) );
            }
            
            if( text=="/account" ) {
               SendMessage( chat.m_id, BotAccount() );
            }
            

            //--- start
            if(text=="/start")
              {
               SendMessage(chat.m_id,"Click on the buttons",ReplyKeyboardMarkup(GetKeyboard(),false,false));
              }

            //--- Click on a RadioButton
            int total=ArraySize(m_radio_button);
            for(int k=0;k<total;k++)
              {
               if(text==RADIO_EMPTY+" "+m_radio_button[k])
                 {
                  m_radio_index=k;
                  SendMessage(chat.m_id,m_radio_button[k],ReplyKeyboardMarkup(GetKeyboard(),false,false));
                 }
              }

            //--- Unlock
            if(text==LOCK_CODE+" "+LOCK_TEXT)
              {
               m_lock_state=false;
               SendMessage(chat.m_id,UNLOCK_TEXT,ReplyKeyboardMarkup(GetKeyboard(),false,false));
              }

            //--- Lock
            if(text==UNLOCK_CODE+" "+UNLOCK_TEXT)
              {
               m_lock_state=true;
              SendMessage(chat.m_id,LOCK_TEXT,ReplyKeyboardMarkup(GetKeyboard(),false,false));
              }

            //--- Unmute
            if(text==MUTE_CODE+" "+MUTE_TEXT)
              {
               m_mute_state=false;
               SendMessage(chat.m_id,UNMUTE_TEXT,ReplyKeyboardMarkup(GetKeyboard(),false,false));
              }

            //--- Mute
            if(text==UNMUTE_CODE+" "+UNMUTE_TEXT)
              {
               m_mute_state=true;
               SendMessage(chat.m_id,MUTE_TEXT,ReplyKeyboardMarkup(GetKeyboard(),false,false));
              }
           
            
     
            msg = StringConcatenate(msg,"My commands list:",NL);
            msg = StringConcatenate(msg,"/ordertotal-return count of orders",NL);
            msg = StringConcatenate(msg,"/ordertrade-return ALL opened orders",NL);
            msg = StringConcatenate(msg,"/orderticket <ticket>-return an order or a chain of history by ticket",NL);
            msg = StringConcatenate(msg,"/historytotal-return count of history",NL);
            msg = StringConcatenate(msg,"/historyticket <ticket>-return a history or chain of history by ticket",NL);
            msg = StringConcatenate(msg,"/account-return account info",NL);
            msg = StringConcatenate(msg,"/help-get help");
            if( text=="/help" ) {
               SendMessage( chat.m_id, msg );
            }
         }
      }
   }
};