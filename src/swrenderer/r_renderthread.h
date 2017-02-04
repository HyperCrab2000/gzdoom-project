/*
**  Renderer multithreading framework
**  Copyright (c) 2016 Magnus Norddahl
**
**  This software is provided 'as-is', without any express or implied
**  warranty.  In no event will the authors be held liable for any damages
**  arising from the use of this software.
**
**  Permission is granted to anyone to use this software for any purpose,
**  including commercial applications, and to alter it and redistribute it
**  freely, subject to the following restrictions:
**
**  1. The origin of this software must not be misrepresented; you must not
**     claim that you wrote the original software. If you use this software
**     in a product, an acknowledgment in the product documentation would be
**     appreciated but is not required.
**  2. Altered source versions must be plainly marked as such, and must not be
**     misrepresented as being the original software.
**  3. This notice may not be removed or altered from any source distribution.
**
*/

#pragma once

#include <memory>

class DrawerCommandQueue;
typedef std::shared_ptr<DrawerCommandQueue> DrawerCommandQueuePtr;

namespace swrenderer
{
	class VisibleSpriteList;
	class RenderPortal;
	class RenderOpaquePass;
	class RenderTranslucentPass;
	class RenderPlayerSprites;
	class RenderScene;
	class Clip3DFloors;
	class VisiblePlaneList;
	class DrawSegmentList;
	class RenderClipSegment;
	class RenderMemory;
	class SWPixelFormatDrawers;
	class SWTruecolorDrawers;
	class SWPalDrawers;

	class RenderThread
	{
	public:
		RenderThread(RenderScene *scene, bool mainThread = true);
		~RenderThread();

		RenderScene *Scene;
		int X1 = 0;
		int X2 = MAXWIDTH;
		bool MainThread = false;

		std::unique_ptr<RenderMemory> FrameMemory;
		std::unique_ptr<RenderOpaquePass> OpaquePass;
		std::unique_ptr<RenderTranslucentPass> TranslucentPass;
		std::unique_ptr<VisibleSpriteList> SpriteList;
		std::unique_ptr<RenderPortal> Portal;
		std::unique_ptr<Clip3DFloors> Clip3DFloors;
		std::unique_ptr<RenderPlayerSprites> PlayerSprites;
		std::unique_ptr<VisiblePlaneList> PlaneList;
		std::unique_ptr<DrawSegmentList> DrawSegments;
		std::unique_ptr<RenderClipSegment> ClipSegments;
		DrawerCommandQueuePtr DrawQueue;

		// VisibleSprite working buffers
		short clipbot[MAXWIDTH];
		short cliptop[MAXWIDTH];

		SWPixelFormatDrawers *Drawers();
		
	private:
		std::unique_ptr<SWTruecolorDrawers> tc_drawers;
		std::unique_ptr<SWPalDrawers> pal_drawers;
	};
}
