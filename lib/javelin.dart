/*

  Copyright (C) 2012 John McCutchan <john@johnmccutchan.com>
  
  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

#library('Javelin');
#import('dart:math', prefix:'Math');
#import('dart:html');
#import('dart:json');
#import('package:DartVectorMath/vector_math_html.dart');
#import('package:spectre/spectre.dart');
#import('package:markerprof/profiler.dart');
#source('package:javelin/javelin/config.dart');
#source('package:javelin/javelin/config_ui.dart');
#source('package:javelin/javelin/keyboard.dart');
#source('package:javelin/javelin/mouse.dart');
#source('package:javelin/javelin/base_demo.dart');
#source('package:javelin/javelin/render_config.dart');