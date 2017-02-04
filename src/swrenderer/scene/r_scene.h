//
// Copyright (C) 1993-1996 by id Software, Inc.
//
// This source is available for distribution and/or modification
// only under the terms of the DOOM Source Code License as
// published by id Software. All rights reserved.
//
// The source is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License
// for more details.
//

#pragma once

#include <stddef.h>
#include <memory>
#include "r_defs.h"
#include "d_player.h"

extern cycle_t FrameCycles;

namespace swrenderer
{
	extern cycle_t WallCycles, PlaneCycles, MaskedCycles, WallScanCycles;

	class RenderThread;
	
	class RenderScene
	{
	public:
		RenderScene();

		void Init();
		void ScreenResized();
		void Deinit();	

		void SetClearColor(int color);
		
		void RenderView(player_t *player);
		void RenderViewToCanvas(AActor *actor, DCanvas *canvas, int x, int y, int width, int height, bool dontmaplines = false);
	
		bool DontMapLines() const { return dontmaplines; }

		RenderThread *MainThread() { return Threads.front().get(); }

	private:
		void RenderActorView(AActor *actor, bool dontmaplines = false);
		void RenderDrawQueues();
		void RenderThreadSlices();
		void RenderThreadSlice(RenderThread *thread);
		
		bool dontmaplines = false;
		int clearcolor = 0;

		std::vector<std::unique_ptr<RenderThread>> Threads;
	};
}
