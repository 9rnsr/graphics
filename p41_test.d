import dgl.frame;

import win32.windows;

class TestFrame : TopFrame
{
	override LRESULT platformWndProc(DefProc defProc, uint msg, WPARAM wp, LPARAM lp)
	{
		switch(msg)
		{
		case WM_PAINT:
			onPaint();
			break;
		case WM_SIZE:
			InvalidateRect(platformHandle, null, TRUE);
			break;
		default:
			break;
		}
		
		return super.platformWndProc(defProc, msg, wp, lp);
	}
	
	void onPaint()
	{
		PAINTSTRUCT ps;
		auto hdc = BeginPaint(platformHandle, &ps);
		scope(exit) EndPaint(platformHandle, &ps);
		
		Rect rc;
		GetClientRect(platformHandle, rc.ptr);
		
		auto center = centerPoint(rc);
		
		immutable sizeCircle = 60;
		auto offset = Size(sizeCircle/2, sizeCircle/2);
		auto size = Size(sizeCircle, sizeCircle);
		auto rectCircle = Rect(center - offset, size);
		
		auto hBrush = CreateSolidBrush(RGB(0, 0, 0));
		scope(exit) DeleteObject(hBrush);
		
		auto hOrgBrush = SelectObject(hdc, hBrush);
		scope(exit) SelectObject(hdc, hOrgBrush);
		
		Ellipse(hdc, rectCircle.left, rectCircle.top, rectCircle.right, rectCircle.bottom);
	}
	Point centerPoint(ref Rect r)
	{
		return Point(
			r.width / 2 + r.left,
			r.height / 2 + r.top);
	}
}

void main()
{
	auto f = new TestFrame();
	f.show();
	MsgLoop.run(&onIdle);
}

void onIdle()
{
}

