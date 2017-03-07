/*********************************************************************
 * Title : MocCon Model
 * Team  : Hayakawa, Usami
 * Date  : 2017/03/12
 *********************************************************************/
/*
1234567890123456789012345678901234567890123456789012345678901234567890
*/

mtype = { TAIKI, HATSU, CHAKU, TSUUWA, INIT, WAIT,
          a_hatsu, a_outou, a_chuushi, a_kyohi, a_shuuryou,
	  b_hatsu, b_outou, b_chuushi, b_kyohi, b_shuuryou };
mtype = { CLEAR, SAVE };

chan ch_ope = [0] of { mtype };	/* ユーザー操作用チャネル */
chan ch_com = [0] of { mtype };	/* 他通信端末との通信用チャネル */

mtype recv_unit;     /* 受信装置の状態 */
mtype reset_unit;    /* リセット装置の状態 */


/*********************************************************************
 * 通信端末
 *********************************************************************/
proctype com_unit()
{
	recv_unit = TAIKI;		/** 受信装置の初期化 **/
	reset_unit = INIT;		/** リセット装置の初期化 **/
	
	byte mtx = 0;			/** 同時接続数 (0, 1, 2) **/
	byte CHAKU_ST = CLEAR;		/** 着信ログ状態 (CLEAR/SAVE) **/
	byte KYOHI_1_ST = CLEAR;	/** 拒否ログ状態 (CLEAR/SAVE) **/
	byte KYOHI_2_ST = CLEAR;	/** 拒否ログ状態 (CLEAR/SAVE) **/
	int  Chaku_log = 0;		/** 着信ログ数 0<Log<xxx **/
	int  Kyohi_1_log = 0;		/** 拒否ログ数 0<Log<xxx **/
	int  Kyohi_2_log = 0;		/** 拒否ログ数 0<log<xxx **/
	bool reset = false;		/** リセットフラグ **/

	do
	::
		do
		::recv_unit == TAIKI;
			if
			::ch_ope ? a_hatsu -> recv_unit = HATSU;
			::ch_com ? b_hatsu -> recv_unit = CHAKU;
				if
				::CHAKU_ST == SAVE ->
					if
					::Chaku_log == 4999 -> CHAKU_ST = CLEAR;
						if
						::reset == false -> reset = !(reset);
						fi;
					fi;
				fi;
				if
				::Chaku_log < 10000 -> Chaku_log++
				fi;
			fi;
		::recv_unit == HATSU;
			if
			::ch_ope ? a_chuushi -> recv_unit = TAIKI;
			::ch_com ? b_outou -> recv_unit = TSUUWA; mtx = 1;
			::ch_com ? b_kyohi -> recv_unit = TAIKI;
				if
				::KYOHI_2_ST == SAVE ->
					if
					::Kyohi_2_log == 899 -> KYOHI_2_ST = CLEAR
						if
						::reset == false -> reset = !(reset)
						fi;
					fi;
				fi;
				if
				::Kyohi_2_log < 1800 -> Kyohi_2_log++
				fi;
			fi;
		::recv_unit == CHAKU;
			if
			::ch_ope ? a_outou -> TSUUWA;
				if
				::mtx == 0 -> mtx = 1;
				::mtx == 1 -> mtx = 2;
				fi;
			::ch_ope ? a_kyohi ->
				if
				::mtx == 0 -> recv_unit = TAIKI;
				::mtx == 1 -> recv_unit = TSUUWA;
				fi;
				if
				::KYOHI_1_ST == SAVE ->
					if
					::Kyohi_1_log == 1499 -> KYOHI_1_ST = CLEAR
						if
						::reset == false -> reset = !(reset);
						fi;
					fi;
				fi;
				if
				::Kyohi_1_log < 3000 -> Kyohi_1_log++
				fi;
			::ch_ope ? a_shuuryou ->
				if
				::mtx == 1 -> mtx = 0;
				::mtx == 2 -> mtx = 1;
				fi;
			::ch_com ? b_chuushi -> 
				if
				::mtx == 0 -> recv_unit = TAIKI;
				::mtx == 1 -> recv_unit = TSUUWA;
				fi;
			::ch_com ? b_shuuryou ->
				if
				::mtx == 1 -> mtx = 0;
				::mtx == 2 -> mtx = 1;
				fi;
			fi;
		::recv_unit == TSUUWA;
			if
			::ch_ope ? a_shuuryou ->
				if
				::mtx == 1 -> recv_unit = TAIKI;
				fi;
				if
				::mtx == 1 -> mtx = 0;
				::mtx == 2 -> mtx = 1;
				fi;
			::ch_com ? b_hatsu ->
				if
				::mtx == 1 -> recv_unit = CHAKU;
				fi;
				if
				::mtx == 1 ->
					if
					::CHAKU_ST == SAVE ->
						if
						::Chaku_log == 4999 -> CHAKU_ST = CLEAR;
							if
							::reset == false -> reset = !(reset);
							fi;
						fi;
					fi;
					if
					::Chaku_log < 10000 -> Chaku_log++
					fi;
				fi;
			::ch_com ? b_shuuryou ->
				 if
				 ::mtx == 1 -> recv_unit = TAIKI;
				 fi;
				 if
				 ::mtx == 1 -> mtx = 0;
				 ::mtx == 2 -> mtx = 1;
				 fi;
			fi;
		od;
		do
		::reset_unit == INIT -> reset_unit = WAIT;
		::reset_unit == WAIT -> skip;
		od;
	od;
}

/*********************************************************************
 * ユーザーa　（テスト用外部環境）
 *	ランダムに通信端末(com_unit)を操作する
 *********************************************************************/
proctype user_a()
{
	do
	::ch_ope! a_hatsu;
	::ch_ope! a_outou;
	::ch_ope! a_chuushi;
	::ch_ope! a_kyohi;
	::ch_ope! a_shuuryou;
	od;
}

/*********************************************************************
 * 他通信端末b　（テスト用外部環境）
 *	テスト対象のcom_unitに操作メッセージをランダムに送信する
 *	（ランダムに通信端末(com_unit_b)を操作している状態をモデル化）
 *********************************************************************/
proctype com_unit_b()
{
	do
	::ch_com! b_hatsu;
	::ch_com! b_outou;
	::ch_com! b_chuushi;
	::ch_com! b_kyohi;
	::ch_com! b_shuuryou;
	od;
}

/*********************************************************************
 * 実行
 *********************************************************************/
init {
	run com_unit();
	run user_a();
	run com_unit_b();
	run com_unit_b();
}
