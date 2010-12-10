module dgl.internal.msgloop;

//import dgl.common;
public import
	dgl.frame;

private import
	win32.windows;


/// 
class MsgLoop
{
	alias bool delegate() IdleMsgProc;		// 何らかの処理を行った場合はtrueを返す
	
	package static uint frameCount = 0;
	
	static int run(IdleMsgProc idleProc=null)
	{
		return run(null, idleProc);
	}
	static int run(HWND hwndModal, IdleMsgProc idleProc=null)
	{
		HWND hOwner = hwndModal ? GetWindow(hwndModal, GW_OWNER) : null;
		bool bSendEnterIdle = (hOwner ? !(GetWindowLong(hOwner, GWL_STYLE) & DS_NOIDLEMSG) : false);
		int	result;
		MSG msg;
		
		if( !idleProc ) idleProc = delegate bool(){ return false; };
		
	msgloop:
		for( ; ; ){
			while( PeekMessage(&msg, null, 0, 0, PM_REMOVE) ){
				if( msg.message == WM_QUIT ){
					result = msg.wParam;
					break msgloop;
				}else{
				//	if( !TranslateAccel(msg.hwnd, &msg) ){	//090313mask
						TranslateMessage(&msg);
						DispatchMessage(&msg);
				//	}
				}
			}
			
			if( frameCount == 0 ) exit(0);
			if( bSendEnterIdle ){
				SendMessage(hOwner, WM_ENTERIDLE, MSGF_DIALOGBOX, cast(LPARAM)hwndModal);
			}
			if( !idleProc() ) WaitMessage();
		}
		
		return result;
	}
	
	/// メッセージループを抜ける
	static void exit(int code)
	{
		PostQuitMessage(code);
	}
}

