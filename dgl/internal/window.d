module dgl.internal.window;

public import win32.windows;


/// 
package WindowHandleMap handleMap;

///
alias LRESULT delegate(uint msg, WPARAM wp, LPARAM lp) DefProc;
///
alias LRESULT delegate(DefProc defaultProc, uint msg, WPARAM wp, LPARAM lp) WndProc;

/**
 *
 */
struct WindowHandleMap
{
  private:
	// 関数のスコープを越えた同期を行うために必要となる
	// クリティカルセクションオブジェクト
	static class CriticalSection
	{
	  private:
		CRITICAL_SECTION cs;
		
	  public:
		this()			{ InitializeCriticalSection(&cs); }
		~this()			{ DeleteCriticalSection(&cs); }
		void enter()	{ EnterCriticalSection(&cs); }
		void leave()	{ LeaveCriticalSection(&cs); }
	}
	private static /*__gshared*/ CriticalSection	cs;
	
	static this()
	{
		cs = new CriticalSection();
	}
	
	// Procedure - Handle対応表でオリジナルのWndProcを保存する構造体
	static struct DispatchInfo
	{
		WndProc receiver;
		WNDPROC original;
	}
	package static DispatchInfo[HWND]	map;

  public:
	HWND attachCreate(lazy HWND createHandle, WndProc receiver, scope void delegate(HWND) init)
	{
		cs.enter();		// ENTER critical section !!
		{
			static WndProc		s_receiver;
			static typeof(init)	s_initfunc;
			static HHOOK		hCBTHook;
			
			// CBTフックを使用して、全てのメッセージに先んじてサブクラス化を完了する
			extern (Windows)
			static LRESULT platformCBTProc(int code, WPARAM wp, LPARAM lp)
			{
				if (code == HCBT_CREATEWND){
					HWND hwnd = cast(HWND)wp;
					UnhookWindowsHookEx(hCBTHook);
					hCBTHook = cast(HHOOK)null;
					
					bool result = handleMap.attach(hwnd, s_receiver);
					assert(result == true);
					s_initfunc(hwnd);
					
				//	s_receiver = null;		// do not need
				//	s_initfunc = null;
				//	
					cs.leave();		// LEAVE critical section !!
				}
				return 0;
			}

			s_receiver = receiver;
			s_initfunc = init;
			hCBTHook = SetWindowsHookEx(
				WH_CBT, &platformCBTProc, GetModuleHandle(null), GetCurrentThreadId());
			
			return createHandle();
		}
	}

	/// ウインドウハンドルにdelegateを関連付ける
	bool attach(HWND handle, WndProc receiver)
	in{
		assert(handle != null);
		assert(receiver !is null);
	}out(result){
		if (result)
		{
			auto di = handle in map;
			assert(di != null);
			assert(di.receiver == receiver);
		}
	}body{
		/// ウインドウメッセージをhookしてdelegateに分配する
		extern (Windows)
		static LRESULT platformSubclassProc(HWND hwnd, uint msg, WPARAM wp, LPARAM lp)
		{
			auto di = hwnd in map;
			LRESULT result;
			
			if (di)
			{
				LRESULT defaultProc(uint msg, WPARAM wp, LPARAM lp)
				{
					return di.original(hwnd, msg, wp, lp);
				}
				
				result = di.receiver(&defaultProc, msg, wp, lp);
				
				if (msg == WM_NCDESTROY)
					handleMap.detach(hwnd);
			}
			else
			{
				result = DefWindowProc(hwnd, msg, wp, lp);
			}
			
			return result;
		}
		
		if (handle in map)
		{
			// 同じハンドルにdelegateを２つ以上関連付けることはできない
			return false;
		}
		else
		{
			auto original = cast(WNDPROC)
				SetWindowLong(handle, GWL_WNDPROC, cast(LONG)&platformSubclassProc);
			assert(original != &platformSubclassProc);
			
			map[handle] = DispatchInfo(receiver, original);
			return true;
		}
	}
	
	/// ウインドウハンドルとdelegateの関連付けを解除する
	void detach(HWND handle)
	{
		cs.enter();					// ENTER critical section !!
		scope(exit) cs.leave();		// LEAVE critical section !!
		
		auto di = handle in map;
		if (di)
		{
			SetWindowLong(handle, GWL_WNDPROC, cast(LONG)di.original);
			map.remove(handle);
		}
	}

  // utilities
  public:
	WndProc hwnd2receiver(HWND handle)
	{
		WndProc receiver;
		if (auto pi = (handle in map)){
			receiver = pi.receiver;
		}
		return receiver;
	}
	WNDPROC hwnd2orgproc(HWND handle)
	{
		WNDPROC orgproc;
		if (auto pi = (handle in map)){
			orgproc = pi.original;
		}
		return orgproc;
	}
}



/// 
mixin template WindowModule(alias proc=void)
{
	static if (is(proc == void))
	{
		LRESULT platformWndProc(DefProc defProc, uint msg, WPARAM wp, LPARAM lp)
		{
			return defProc(msg, wp, lp);
		}
	}
	else// static if (is(typeof(proc) == WndProc))
	{
		alias proc platformWndProc;
	}
//	else
//	{
//		static assert(0, "invalid type of proc : " ~ typeof(proc).stringof);
//	}
	
	private HWND platformHWnd = null;

	/// 
	HWND platformHandle() const	{ return cast(HWND)platformHWnd; }
//	HWND platformHandle()		{ return platformHWnd; }

	/// ウインドウハンドルを関連付ける
	final void platformAttach(lazy HWND hwnd)
	{
		handleMap.attachCreate(hwnd, &proc, (HWND hwnd){ platformHWnd = hwnd; return; });
	}
	/// ウインドウハンドルの関連付けを解除する
	final void platformDetach()
	out{
		assert(platformHandle == null);
	}body{
		handleMap.detach(platformHandle);
	//	//WM_NCDESTROYで自動Detachされるので、Handleを潰すだけでよい
		platformHWnd = null;
	}

	///	Nativeのウインドウ階層における親Windowを取得する
	final HWND platformParent() const
	in{
		assert(platformHandle != null);
	}body{
		HWND hParent = GetParent(platformHandle);
		return (hParent && IsChild(hParent, platformHandle)) ? hParent : null;
	}
	
/+	/// 直下のWindow階層にあるWindowを列挙する
	final int delegate(int delegate(ref Window)) children()
	in{
		assert(platformHandle != null);
	}body{
		return (int delegate(ref Window) dg){
			HWND hwnd = GetWindow(platformHandle, GW_CHILD);
			while (hwnd != null){
				if (auto r = hwnd2rcvr(hwnd)){
					if (auto result=dg(r)) return result;
				}
				hwnd = GetWindow(hwnd, GW_HWNDNEXT);
			}
			return 0;
		};
	}+/
}
