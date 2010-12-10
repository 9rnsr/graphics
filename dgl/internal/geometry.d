/**
 *	Authors: K.Hara
 *	License: undefined
 **/
module dgl.internal.geometry;

import std.algorithm;
import std.string;


/// 
struct Point
{
	int x, y;

//	static Point opCall()				{ return Point(0, 0); }
//	static Point opCall(int x, int y)	{ Point p; p.x=x, p.y=y; return p; }
	this(int x, int y)	{ this.x=x, this.y=y; }
	
	bool  opEquals()(auto ref const(Point) p) const
	{ return (x == p.x && y == p.y); }
	Point opNeg() const							{ return Point(-x, -y); }
	
	ref Point opAddAssign(const(Size) s)		{ x += s.cx; y += s.cy; return this; }
	ref Point opSubAssign(const(Size) s)		{ x -= s.cx; y -= s.cy; return this; }
		Point opAdd(const(Size) s) const		{ return Point(x + s.cx, y + s.cy); }
		Point opSub(const(Size) s) const		{ return Point(x - s.cx, y - s.cy); }
	
  version(Windows){
	import win32.windef : POINT;
	//alias .win32.windef.POINT POINT;
	POINT* ptr()						{ return cast(POINT*)&this; }
  }
	
	string toString() const				{ return format("Point(%d,%d)", x, y); }
//	string toString()					{ return (cast(const)this).toString(); }
}


/// 
struct Size
{
	int cx, cy;

//	static Size opCall()				{ return Size(0, 0); }
//	static Size opCall(int cx, int cy)	{ Size s; s.cx = cx, s.cy = cy; return s; }
	this(int cx, int cy)	{ this.cx = cx, this.cy = cy; }
	
	bool opEquals()(auto ref const(Size) s) const
	{ return (cx == s.cx && cy == s.cy); }
	
	Size opNeg() const						{ return Size(-cx, -cy); }
	
	ref Size opAddAssign(const(Size) s)		{ cx += s.cx; cy += s.cy; return this; }
	ref Size opSubAssign(const(Size) s)		{ cx -= s.cx, cy -= s.cy; return this; }
		Size opAdd(const(Size) s) const		{ return Size(cx + s.cx, cy + s.cy); }
		Size opSub(const(Size) s) const		{ return Size(cx - s.cx, cy - s.cy); }
	
  version(Windows){
	import win32.windef : SIZE;
	//alias .win32.windef.SIZE SIZE;
	SIZE* ptr()							{ return cast(SIZE*)&this; }
  }
	
	string toString() const				{ return format("Size(%d,%d)", cx, cy); }
//	string toString()					{ return (cast(const)this).toString(); }
}


/// 
struct Rect
{
//	struct { int left, top, right, bottom; }
//	struct { Point topLeft, bottomRight; }
	int left, top, right, bottom;
	
	alias left		L;
	alias top		T;
	alias right		R;
	alias bottom	B;

//	static Rect opCall()							{ return Rect(0, 0, 0, 0); }
//	static Rect opCall(Point p, Size s)				{ return Rect(p.x, p.y, p.x+s.cx, p.y+s.cy); }
//	static Rect opCall(Point pTL, Point pBR)		{ return Rect(pTL.x, pTL.y, pBR.x, pBR.y); }
//	static Rect opCall(int l, int t, int r, int b)	{ Rect rc = {l, t, r, b}; return rc; }
	
	this(Point p, Size s)					{ left = p.x,   top = p.y,   right = p.x+s.cx, bottom = p.y+s.cy; }
	this(Point pTL, Point pBR)				{ left = pTL.x, top = pTL.y, right = pBR.x,    bottom = pBR.y; }
	this(int l, int t, int r, int b)		{ left = l,     top = t,     right = r,        bottom = b; }

	bool opEquals()(auto ref const(Rect) rc) const
	{ return (L == rc.L && T == rc.T && R == rc.R && B == rc.B); }
	
	/// Offsetを計算する
	ref Rect opAddAssign(const(Size) s)		{ L+=s.cx, T+=s.cy, R+=s.cx, B+=s.cy; return this; }	/// ditto
	ref Rect opSubAssign(const(Size) s)		{ L-=s.cx, T-=s.cy, R-=s.cx, B-=s.cy; return this; }	/// ditto
		Rect opAdd(const(Size) s) const		{ return Rect().opAddAssign(s); }						/// ditto
		Rect opSub(const(Size) s) const		{ return Rect().opSubAssign(s); }						/// ditto
	
	/// 積(intersect)を計算する
	ref Rect opAndAssign(const(Rect) rc)	{ L=max(L,rc.L), T=max(T,rc.T), R=min(R,rc.R), B=min(B,rc.B); return this; }
		Rect opAnd(const(Rect) rc) const	{ Rect lhs = this; return lhs.opAndAssign(rc); }		/// ditto
	/// 和(union)を計算する
	ref Rect opOrAssign(const(Rect) rc)		{ L=min(L,rc.L), T=min(T,rc.T), R=max(R,rc.R), B=max(B,rc.B); return this; }									// 和計算のop=版
		Rect opOr(const(Rect) rc) const		{ Rect lhs = this; return lhs.opOrAssign(rc); }			/// ditto
	
	ref Rect inflate(int dx, int dy)		{ L-=dx, T-=dy, R+=dx, B+=dy; return this; }
	
	bool  empty() const				{ return (R <= L) || (B <= T); }
	int   width() const				{ return R - L; }
//	uint  width(uint w)				{ R = L + w; return w; }
	int   height() const			{ return B - T; }
//	uint  height(uint h)			{ B = T + h; return h; }
	Size  extent() const			{ return Size(width(), height()); }

	Point topLeft() const			{ return Point(L, T); }
//	Point topLeft(Point pt)			{ int w=width(), h=height(); L = pt.x, T = pt.y, R = L + w, B = T + h; return pt; }
	Point topRight() const			{ return Point(R, T); }
	Point bottomLeft() const		{ return Point(L, B); }
	Point bottomRight() const		{ return Point(R, B); }
	
	bool contains(const(Point) pt) const	{ return (L<=pt.x && pt.x<R) && (T<=pt.y && pt.y<B); }
	
  version(Windows){
	import win32.windef : RECT;
	//alias .win32.windef.RECT RECT;
	RECT* ptr()						{ return cast(RECT*)&this; }
  }
	
	string toString() const			{ return format("Rect(%d,%d)-(%d,%d)", left, top, right, bottom); }
//	string toString()				{ return (cast(const)this).toString(); }

//	invariant	{ assert(left <= right && top <= bottom); }
}
