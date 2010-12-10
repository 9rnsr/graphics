module dgl.frame;

public
	import dgl.internal.msgloop;

import dgl.internal.window;
import std.utf;

pragma(lib, "gdi32.lib");


/**
 *
 */
class TopFrame
{
private:
	enum classname = "DGLFrameClass"w;    //ウィンドウクラス
	
	static this()
	{
		//ウィンドウ・クラスの登録
		WNDCLASSEX wc;
		wc.cbSize			= WNDCLASSEX.sizeof;
		wc.style			= 0;//CS_HREDRAW | CS_VREDRAW;		//CoolBarのちらつき低減
		wc.lpfnWndProc		= &DefWindowProc;
		wc.cbClsExtra		= 0;
		wc.cbWndExtra		= 0;
		wc.hInstance		= GetModuleHandle(null);
		wc.hIcon			= LoadIcon(null, IDI_APPLICATION);
		wc.hCursor			= LoadCursor(null, IDC_ARROW);
		wc.hbrBackground	= cast(HBRUSH)GetStockObject(WHITE_BRUSH);
		wc.lpszMenuName		= null;			//メニュー名
		wc.lpszClassName	= classname.ptr;
		wc.hIconSm			= LoadIcon(null, IDI_APPLICATION);
		RegisterClassEx(&wc);
	}

private:
//	Widget widget;
	const(wchar)*	cstr_title;
//	bool handyPosChanging = false;

public:
	this(string title=null)
	{
		cstr_title = title.toUTF16z;
		
		create();
	}
	
	/// ウィンドウの生成
	void create()
	{
		HWND	hOwner		= /*owner() ? owner().platformHandle : */null;
		DWORD	dwStyle		= WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN;
		DWORD	dwExStyle	= WS_EX_WINDOWEDGE | WS_EX_CONTROLPARENT;
		
		platformAttach(
			CreateWindowEx(
				dwExStyle,
				classname.ptr,
				cstr_title,					//タイトルバーにこの名前が表示されます
				dwStyle,
				CW_USEDEFAULT,				//Ｘ座標
				CW_USEDEFAULT,				//Ｙ座標
				CW_USEDEFAULT,				//幅
				CW_USEDEFAULT,				//高さ
				hOwner,						//親ウィンドウのハンドル、親を作るときはnull
				null,						//メニューハンドル、クラスメニューを使うときはnull
				GetModuleHandle(null),		//インスタンスハンドル
				null)
		);
	}
	
	void show()
	{
		//表示時はActiveになる
		ShowWindow(platformHandle, SW_SHOW);
	}
	
//	void resize(Rect r)
//	{
//		if (!handyPosChanging){
//			super.resize(r);
//		}
//	}

	/// フレームを所有するオーナーフレームを取得する
	HWND owner() const
	{
		//ウィンドウスタイルに WS_CHILD が含まれていないことを確認して、
		//GetWindowLong() で GWL_HWNDPARENT フィールドを取得する、でも可能
		return GetWindow(platformHandle, GW_OWNER);
	}
	HWND owner(HWND hOwner)
	{
		return cast(HWND)SetWindowLong(platformHandle, GWL_HWNDPARENT, cast(LONG)hOwner);
	}

	
  protected:
	//ウィンドウプロシージャ
	LRESULT platformWndProc(DefProc defProc, uint msg, WPARAM wp, LPARAM lp)
	{
		switch( msg ){
		case WM_CREATE:
			// Widgetの初期サイズを設定する
	//		assert(widget.created == false);
			RECT r;
			GetWindowRect(platformHandle, &r);
	//		widget.bound = r;
			
			++MsgLoop.frameCount;
			break;
		case WM_DESTROY:
			if (--MsgLoop.frameCount == 0)
				PostQuitMessage(0);
			break;
		case WM_WINDOWPOSCHANGED:
		{
	//		handyPosChanging = true;
	//		scope(exit) handyPosChanging = false;
			
			RECT r;
			GetWindowRect(platformHandle, &r);
	//		widget.bound = r;
			
			//p("WindowPosChanged: %s", widget.bound);
			break;
		}
	  version(none)
	  {
		case WM_SIZE:
	//		auto rc = clientRect;
	//		foreach (w; children)
	//		{
	//			w.regionRect = rc;
	//		}
			break;
	  }
		default:
			break;
		}
	//	return super.platformWndProc(defProc, msg, wp, lp);
		return defProc(msg, wp, lp);
	}

	mixin WindowModule!(platformWndProc);
}
