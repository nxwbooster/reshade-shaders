////--------------------//
///**SuperDepth3D_VR+**///
//--------------------////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//* Depth Map Based 3D post-process shader v2.6.3
//* For Reshade 4.4+ I think...
//* ---------------------------------
//*
//* Original work was based on the shader code from
//* Also Fu-Bama a shader dev at the reshade forums https://reshade.me/forum/shader-presentation/5104-vr-universal-shader
//* Also had to rework Philippe David http://graphics.cs.brown.edu/games/SteepParallax/index.html code to work with ReShade. This is used for the parallax effect.
//* This idea was taken from this shader here located at https://github.com/Fubaxiusz/fubax-shaders/blob/596d06958e156d59ab6cd8717db5f442e95b2e6b/Shaders/VR.fx#L395
//* It's also based on Philippe David Steep Parallax mapping code.
//* Text rendering code Ported from https://www.shadertoy.com/view/4dtGD2 by Hamneggs for ReShadeFX
//* If I missed any information please contact me so I can make corrections.
//*
//* LICENSE
//* ============
//* Overwatch Interceptor & Code out side the work of people mention above is licenses under: Copyright (C) Depth3D - All Rights Reserved
//*
//* Unauthorized copying of this file, via any medium is strictly prohibited
//* Proprietary and confidential.
//*
//* You are allowed to obviously download this and use this for your personal use.
//* Just don't redistribute this file unless I authorize it.
//*
//* Have fun,
//* Written by Jose Negrete AKA BlueSkyDefender <UntouchableBlueSky@gmail.com>, December 2019
//*
//* Please feel free to contact me if you want to use this in your project.
//* https://github.com/BlueSkyDefender/Depth3D
//* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader
//* https://discord.gg/Q2n97Uj
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#if exists "Overwatch.fxh"                                           //Overwatch Interceptor//
	#include "Overwatch.fxh"
	#define OS 0
#else// DA_X = [ZPD] DA_Y = [Depth Adjust] DA_Z = [Offset] DA_W = [Depth Linearization]
	static const float DA_X = 0.025, DA_Y = 7.5, DA_Z = 0.0, DA_W = 0.0;
	// DC_X = [Depth Flip] DC_Y = [Auto Balance] DC_Z = [Auto Depth] DC_W = [Weapon Hand]
	static const float DB_X = 0, DB_Y = 0, DB_Z = 0.1, DB_W = 0.0;
	// DC_X = [Barrel Distortion K1] DC_Y = [Barrel Distortion K2] DC_Z = [Barrel Distortion K3] DC_W = [Barrel Distortion Zoom]
	static const float DC_X = 0, DC_Y = 0, DC_Z = 0, DC_W = 0;
	// DD_X = [Horizontal Size] DD_Y = [Vertical Size] DD_Z = [Horizontal Position] DD_W = [Vertical Position]
	static const float DD_X = 1, DD_Y = 1, DD_Z = 0.0, DD_W = 0.0;
	// DE_X = [ZPD Boundary Type] DE_Y = [ZPD Boundary Scaling] DE_Z = [ZPD Boundary Fade Time] DE_W = [Weapon Near Depth Max]
	static const float DE_X = 0, DE_Y = 0.5, DE_Z = 0.25, DE_W = 0.0;
	// DF_X = [Weapon ZPD Boundary] DF_Y = [Separation] DF_Z = [Null] DF_W = [HUD]
	static const float DF_X = 0.0, DF_Y = 0.0, DF_Z = 0.0, DF_W = 0.0;
	// DG_X = [ZPD Balance] DG_Y = [Null] DG_Z = [Weapon Near Depth Min] DG_W = [Check Depth Limit]
	static const float DG_X = 0.5, DG_Y = 0.0, DG_Z = 0.0, DG_W = 0.0;
	// WSM = [Weapon Setting Mode]
	#define OW_WP "WP Off\0Custom WP\0"
	static const int WSM = 0;
	//Triggers
	static const int RE = 0, NC = 0, RH = 0, NP = 0, ID = 0, SP = 0, DC = 0, HM = 0, DF = 0, NF = 0, DS = 0, BM = 0, LBC = 0, LBM = 0, DA = 0, NW = 0, PE = 0, WW = 0, FV = 0, ED = 0, SDT = 0;
	//Overwatch.fxh State
	#define OS 1
#endif
//USER EDITABLE PREPROCESSOR FUNCTIONS START//

// Zero Parallax Distance Balance Mode allows you to switch control from manual to automatic and vice versa.
#define Balance_Mode 0 //Default 0 is Automatic. One is Manual.

// RE Fix is used to fix the issue with Resident Evil's 2 Remake 1-Shot cutscenes.
#define RE_Fix 0 //Default 0 is Off. One is On.

// Change the Cancel Depth Key. Determines the Cancel Depth Toggle Key using keycode info
// The Key Code for Decimal Point is Number 110. Ex. for Numpad Decimal "." Cancel_Depth_Key 110
#define Cancel_Depth_Key 0 // You can use http://keycode.info/ to figure out what key is what.

// Rare Games like Among the Sleep Need this to be turned on.
#define Invert_Depth 0 //Default 0 is Off. One is On.

// Barrel Distortion Correction For SuperDepth3D for non conforming BackBuffer.
#define BD_Correction 0 //Default 0 is Off. One is On.

// Horizontal & Vertical Depth Buffer Resize for non conforming DepthBuffer.
// Also used to enable Image Position Adjust is used to move the Z-Buffer around.
#define DB_Size_Position 0 //Default 0 is Off. One is On.

// Auto Letter Box Correction & Masking
#define LB_Correction 0 //Default 0 is Off. One is On.
#define LetterBox_Masking 0 //[Zero is Off] [One is Hoz] [Two is Auto Hoz] [Three is Vert] [Four is Auto Vert]

// Specialized Depth Triggers
#define SD_Trigger 0 //Default is off. One is Mode A other Modes not added yet.

// HUD Mode is for Extra UI MASK and Basic HUD Adjustments. This is useful for UI elements that are drawn in the Depth Buffer.
// Such as the game Naruto Shippuden: Ultimate Ninja, TitanFall 2, and or Unreal Gold 277. That have this issue. This also allows for more advance users
// Too Make there Own UI MASK if need be.
// You need to turn this on to use UI Masking options Below.
#define HUD_MODE 0 // Set this to 1 if basic HUD items are drawn in the depth buffer to be adjustable.

// -=UI Mask Texture Mask Interceptor=- This is used to set Two UI Masks for any game. Keep this in mind when you enable UI_MASK.
// You Will have to create Three PNG Textures named DM_Mask_A.png & DM_Mask_B.png with transparency for this option.
// They will also need to be the same resolution as what you have set for the game and the color black where the UI is.
// This is needed for games like RTS since the UI will be set in depth. This corrects this issue.
#if ((exists "DM_Mask_A.png") || (exists "DM_Mask_B.png"))
	#define UI_MASK 1
#else
	#define UI_MASK 0
#endif
// To cycle through the textures set a Key. The Key Code for "n" is Key Code Number 78.
#define Set_Key_Code_Here 0 // You can use http://keycode.info/ to figure out what key is what.
// Texture EX. Before |::::::::::| After |**********|
//                    |:::       |       |***       |
//                    |:::_______|       |***_______|
// So :::: are UI Elements in game. The *** is what the Mask needs to cover up.
// The game part needs to be transparent and the UI part needs to be black.

// The Key Code for the mouse is 0-4 key 1 is right mouse button.
#define Cursor_Lock_Key 4 // Set default on mouse 4
#define Fade_Key 1 // Set default on mouse 1
#define Fade_Time_Adjust 0.5625 // From 0 to 1 is the Fade Time adjust for this mode. Default is 0.5625;

// Delay Frame for instances the depth bufferis 1 frame behind useful for games that need "Copy Depth Buffer
// Before Clear Operation," Is checked in the API Depth Buffer tab in ReShade.
#define D_Frame 0 //This should be set to 0 most of the times this will cause latency by one frame.

//Text Information Key Default Menu Key
#define Text_Info_Key 93

//USER EDITABLE PREPROCESSOR FUNCTIONS END//
#if !defined(__RESHADE__) || __RESHADE__ < 40000
	#define Compatibility 1
#else
	#define Compatibility 0
#endif

#if __RESHADE__ >= 40300
	#define Compatibility_DD 1
#else
	#define Compatibility_DD 0
#endif
//DX9 0x9000 and OpenGL
#if __RENDERER__ == 0x9000 || __RENDERER__ >= 0x10000
	#define RenderLimitations 1
#else
	#define RenderLimitations 0
#endif
//DX12 Check
#if __RENDERER__ >= 0xc000
	#define DXTwelve 1
#else
	#define DXTwelve 0
#endif
//DX9 Check
#if __RENDERER__ == 0x9000
	#define DX9 1
#else
	#define DX9 0
#endif
//Resolution Scaling because I can't tell your monitor size.
#if (BUFFER_HEIGHT <= 720)
	#define Max_Divergence 25.0
	#define Set_Divergence 12.5	
#elif (BUFFER_HEIGHT <= 1080)
	#define Max_Divergence 50.0
	#define Set_Divergence 25.0
#elif (BUFFER_HEIGHT <= 1440)
	#define Max_Divergence 75.0
	#define Set_Divergence 37.5
#elif (BUFFER_HEIGHT <= 2160)
	#define Max_Divergence 100.0
	#define Set_Divergence 50.0
#else
	#define Max_Divergence 125.0//Wow Must be the future and 8K Plus is normal now. If you are hear use AI infilling...... Future person.
	#define Set_Divergence 62.5
#endif                          //With love <3 Jose Negrete..
//New ReShade PreProcessor stuff
#if UI_MASK
	#ifndef Mask_Cycle_Key
		#define Mask_Cycle_Key Set_Key_Code_Here
	#endif
#else
	#define Mask_Cycle_Key Set_Key_Code_Here
#endif
//This preprocessor is for Super3D Mode for really close to full Res images per I using Channel Compression
#ifndef Super3D_Mode
	#define Super3D_Mode 0
#endif
#define SuperDepth Super3D_Mode
//This preprocessor is for HelixVision Mode that creates a Double Sized texture on the Horizontal axis.
#ifndef HelixVision_Mode
	#define HelixVision_Mode 0
#endif
//Render Buffer Resolution limit.
#define RenderBufferWidth (BUFFER_WIDTH * 2) > 4096
//Render Buffer Warnings for HelixVision
#if RenderLimitations
	#if RenderBufferWidth
		#define HelixVision 0
		#if HelixVision
			#warning "HelixVision Mode Will NOT work on DirectX 9.0c and OpenGL at current resolution. To Support this consider the Super3D Format for your application." //#error "Will NOT work on DirectX 9.0c and OpenGL."
		#endif
	#else
		#define HelixVision HelixVision_Mode
	#endif
#else
	#define HelixVision HelixVision_Mode
	#if HelixVision
		#if DXTwelve
			#warning "DirectX 12 not supported in the HelixVision app, But, if added should work."
		#endif
	#endif
#endif
//uniform float3 TEST < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; > = 0.0;
#if !SuperDepth && !HelixVision
uniform int IPD <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
	ui_min = 0; ui_max = 100;
	ui_label = "·Interpupillary Distance·";
	ui_tooltip = "Determines the distance between your eyes.\n"
				 "Default is 0.";
	ui_category = "Eye Focus Adjustment";
> = 0;
#else
static const int IPD = 0;
#endif

//Divergence & Convergence//
uniform float Divergence <
	ui_type = "drag";
	ui_min = 10.0; ui_max = Max_Divergence; ui_step = 0.5;
	ui_label = "·Divergence Slider·";
	ui_tooltip = "Divergence increases differences between the left and right retinal images and allows you to experience depth.\n"
				 "The process of deriving binocular depth information is called stereopsis.";
	ui_category = "Divergence & Convergence";
> = Set_Divergence;

uniform float2 ZPD_Separation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.250;
	ui_label = " ZPD & Sepration";
	ui_tooltip = "Zero Parallax Distance controls the focus distance for the screen Pop-out effect also known as Convergence.\n"
				"Separation is a way to increase the intensity of Divergence without a performance cost.\n"
				"For FPS Games keeps this low Since you don't want your gun to pop out of screen.\n"
				"Default is 0.025, Zero is off.";
	ui_category = "Divergence & Convergence";
> = float2(DA_X,DF_Y);
#if Balance_Mode || BM
uniform float ZPD_Balance <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = " ZPD Balance";
	ui_tooltip = "Zero Parallax Distance balances between ZPD Depth and Scene Depth.\n"
				"Default is Zero is full Convergence and One is Full Depth.";
	ui_category = "Divergence & Convergence";
> = DG_X;

static const int Auto_Balance_Ex = 0;
#else
uniform int Auto_Balance_Ex <
	ui_type = "slider";
	ui_min = 0; ui_max = 5;
	ui_label = " Auto Balance";
	ui_tooltip = "Automatically Balance between ZPD Depth and Scene Depth.\n"
				 "Default is Off.";
	ui_category = "Divergence & Convergence";
> = DB_Y;
#endif
uniform int ZPD_Boundary <
	ui_type = "combo";
	ui_items = "BD0 Off\0BD1 Full\0BD2 Narrow\0BD3 FPS Center\0BD04 FPS Right\0";
	ui_label = " ZPD Boundary Detection";
	ui_tooltip = "This selection menu gives extra boundary conditions to ZPD.\n"
				 			 "This treats your screen as a virtual wall.\n"
				 		   "Default is Off.";
	ui_category = "Divergence & Convergence";
> = DE_X;

uniform float2 ZPD_Boundary_n_Fade <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = " ZPD Boundary & Fade Time";
	ui_tooltip = "This selection menu gives extra boundary conditions to scale ZPD & lets you adjust Fade time.";
	ui_category = "Divergence & Convergence";
> = float2(DE_Y,DE_Z);

uniform int View_Mode <
	ui_type = "combo";
	#if !DX9
	ui_items = "VM0 Normal\0VM1 Alpha\0VM2 Reiteration\0VM3 Adaptive\0";
	#else
	ui_items = "VM0 Normal\0VM1 Alpha\0VM2 Reiteration\0";
	#endif
	ui_label = "·View Mode·";
	ui_tooltip = "Changes the way the shader fills in the occlude sections in the image.\n"
				"Normal      | is the default output used for most games with it's streched look.\n"
				"Alpha       | is used for higher amounts of Semi-Transparent objects like foliage.\n"
				"Reiteration | Same thing as Alpha but with brakeage points.\n"
				#if !DX9
				"Adaptive    | is a scene adapting infilling that uses disruptive reiterative sampling.\n"
				"\n"
				"Warning: Adaptive View Mode's performace cost is high in out door scenes.\n"
				"         Also Make sure you turn on Performance Mode before you close this menu.\n"
				#else
				"\n"
				"Warning: Adaptive View Mode's does not work on DX9, please use a wrapper to switch to a other API.\n"
				#endif
				"\n"
				"Default is Normal Medium.";
ui_category = "Occlusion Masking";
> = 0;

uniform float Max_Depth <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
	ui_min = 0.5; ui_max = 1.0;
	ui_label = " Max Depth";
	ui_tooltip = "Max Depth lets you clamp the max depth range of your scene.\n"
				 "So it's not hard on your eyes looking off in to the distance .\n"
				 "Default and starts at One and it's Off.";
	ui_category = "Occlusion Masking";
> = 1.0;

uniform int Performance_Level <
	ui_type = "combo";
	ui_items = "Low\0Med\0High\0";
	ui_label = " Performance Mode";
	ui_tooltip = "Performance Mode Lowers or Raises Occlusion Quality Processing so that there is a performance is adjustable.\n"
				 "Please enable the 'Performance Mode Checkbox,' in ReShade's GUI.\n"
				 "It's located in the lower bottom right of the ReShade's Main UI.\n"
				 "Default is False.";
	ui_category = "Occlusion Masking";
> = 0;
/*
//Luma Based Variable Rate Shading
uniform bool L_VRS <
	ui_label = " Variable Rate Shading";
	ui_tooltip = "Luma Based Variable Rate Shading reallocation occlusion samples at varying rates across the 3D image so save Performance.\n"
				 "Please enable the 'Performance Mode Checkbox,' in ReShade's GUI.\n"
				 "It's located in the lower bottom right of the ReShade's Main UI.\n"
				 "Default is False.";
	ui_category = "Occlusion Masking";
> = false;
*/
uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "DM0 Normal\0DM1 Reversed\0";
	ui_label = "·Depth Map Selection·";
	ui_tooltip = "Linearization for the zBuffer also known as Depth Map.\n"
			     "DM0 is Z-Normal and DM1 is Z-Reversed.\n";
	ui_category = "Depth Map";
> = DA_W;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 1.0; ui_max = 250.0; ui_step = 0.125;
	ui_label = " Depth Map Adjustment";
	ui_tooltip = "This allows for you to adjust the DM precision.\n"
				 "Adjust this to keep it as low as possible.\n"
				 "Default is 7.5";
	ui_category = "Depth Map";
> = DA_Y;

uniform float Offset <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = " Depth Map Offset";
	ui_tooltip = "Depth Map Offset is for non conforming ZBuffer.\n"
				 "It,s rare if you need to use this in any game.\n"
				 "Use this to make adjustments to DM 0 or DM 1.\n"
				 "Default and starts at Zero and it's Off.";
	ui_category = "Depth Map";
> = DA_Z;

uniform float Auto_Depth_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.625;
	ui_label = " Auto Depth Adjust";
	ui_tooltip = "The Map Automaticly scales to outdoor and indoor areas.\n"
				 "Default is 0.1f, Zero is off.";
	ui_category = "Depth Map";
> = DB_Z;

uniform bool Depth_Map_View <
	ui_label = " Depth Map View";
	ui_tooltip = "Display the Depth Map.";
	ui_category = "Depth Map";
> = false;
// New Menu Detection Code
uniform bool Depth_Detection <
	ui_label = " Depth Detection";
	ui_tooltip = "Use this to dissable/enable in game Depth Detection.";
	ui_category = "Depth Map";
> = true;

uniform bool Depth_Map_Flip <
	ui_label = " Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
	ui_category = "Depth Map";
> = DB_X;
#if DB_Size_Position || SP == 2
uniform float2 Horizontal_and_Vertical <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 2;
	ui_label = "·Horizontal & Vertical Size·";
	ui_tooltip = "Adjust Horizontal and Vertical Resize. Default is 1.0.";
	ui_category = "Reposition Depth";
> = float2(DD_X,DD_Y);

uniform float2 Image_Position_Adjust<
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = " Horizontal & Vertical Position";
	ui_tooltip = "Adjust the Image Position if it's off by a bit. Default is Zero.";
	ui_category = "Reposition Depth";
> = float2(DD_Z,DD_W);

uniform bool Alinement_View <
	ui_label = " Alinement View";
	ui_tooltip = "A Guide to help aline the Depth Buffer to the Image.";
	ui_category = "Reposition Depth";
> = false;
#else
static const bool Alinement_View = false;
static const float2 Horizontal_and_Vertical = float2(DD_X,DD_Y);
static const float2 Image_Position_Adjust = float2(DD_Z,DD_W);
#endif
//Weapon Hand Adjust//
uniform int WP <
	ui_type = "combo";
	ui_items = OW_WP;
	ui_label = "·Weapon Profiles·";
	ui_tooltip = "Pick Weapon Profile for your game or make your own.";
	ui_category = "Weapon Hand Adjust";
> = DB_W;

uniform float3 Weapon_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 250.0;
	ui_label = " Weapon Hand Adjust";
	ui_tooltip = "Adjust Weapon depth map for your games.\n"
				 "X, CutOff Point used to set a different scale for first person hand apart from world scale.\n"
				 "Y, Precision is used to adjust the first person hand in world scale.\n"
	             "Default is float2(X 0.0, Y 0.0, Z 0.0)";
	ui_category = "Weapon Hand Adjust";
> = float3(0.0,0.0,0.0);

uniform float3 WZPD_and_WND <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = " Weapon ZPD, Min, and Max";
	ui_tooltip = "WZPD controls the focus distance for the screen Pop-out effect also known as Convergence for the weapon hand.\n"
				"Weapon ZPD Is for setting a Weapon Profile Convergence, so you should most of the time leave this Default.\n"
				"Weapon Min is used to adjust min weapon hand of the weapon hand when looking at the world near you.\n"
				"Weapon Max is used to adjust max weapon hand when looking out at a distance.\n"
				"Default is (ZPD X 0.03, Min Y 0.0, Max Z 0.0) & Zero is off.";
	ui_category = "Weapon Hand Adjust";
> = float3(0.03,DG_Z,DE_W);

uniform int FPSDFIO <
	ui_type = "combo";
	ui_items = "Off\0Press\0Hold Down\0";
	ui_label = " FPS Focus Depth";
	ui_tooltip = "This lets the shader handle real time depth reduction for aiming down your sights.\n"
				 "This may induce Eye Strain so take this as an Warning.";
	ui_category = "Weapon Hand Adjust";
> = 0;

uniform int3 Eye_Fade_Reduction_n_Power <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
	ui_min = 0; ui_max = 2;
	ui_label = " Eye Fade Options";
	ui_tooltip ="X, Eye Selection: One is Right Eye only, Two is Left Eye Only, and Zero Both Eyes.\n"
				"Y, Fade Reduction: Decreases the depth amount by a current percentage.\n"
				"Z, Fade Speed: Decreases or Incresses how fast it changes.\n"
				"Default is X[ 0 ] Y[ 0 ] Z[ 1 ].";
	ui_category = "Weapon Hand Adjust";
> = int3(0,0,0);

uniform float Weapon_ZPD_Boundary <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = " Weapon Screen Boundary Detection";
	ui_tooltip = "This selection menu gives extra boundary conditions to WZPD.";
	ui_category = "Weapon Hand Adjust";
> = DF_X;
#if HUD_MODE || HM
//Heads-Up Display
uniform float2 HUD_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "·HUD Mode·";
	ui_tooltip = "Adjust HUD for your games.\n"
				 "X, CutOff Point used to set a separation point between world scale and the HUD also used to turn HUD MODE On or Off.\n"
				 "Y, Pushes or Pulls the HUD in or out of the screen if HUD MODE is on.\n"
				 "This is only for UI elements that show up in the Depth Buffer.\n"
	             "Default is float2(X 0.0, Y 0.5)";
	ui_category = "Heads-Up Display";
> = float2(DF_W,0.5);
#endif
//Cursor Adjustments
uniform int Cursor_Type <
	ui_type = "combo";
	ui_items = "Off\0FPS\0ALL\0RTS\0";
	ui_label = "·Cursor Selection·";
	ui_tooltip = "Choose the cursor type you like to use.\n"
							 "Default is Zero.";
	ui_category = "Cursor Adjustments";
> = 0;

uniform int2 Cursor_SC <
	ui_type = "drag";
	ui_min = 0; ui_max = 10;
	ui_label = " Cursor Adjustments";
	ui_tooltip = "This controls the Size & Color.\n"
							 "Defaults are ( X 1, Y 2 ).";
	ui_category = "Cursor Adjustments";
> = int2(1,0);

uniform bool Cursor_Lock <
	ui_label = " Cursor Lock";
	ui_tooltip = "Screen Cursor to Screen Crosshair Lock.";
	ui_category = "Cursor Adjustments";
> = false;
#if BD_Correction
uniform int BD_Options <
	ui_type = "combo";
	ui_items = "On\0Off\0Guide\0";
	ui_label = "·Distortion Options·";
	ui_tooltip = "Use this to Turn Off, Turn On, & to use the BD Alinement Guide.\n"
				 "Default is ON.";
	ui_category = "Distortion Corrections";
> = 0;
uniform float3 Colors_K1_K2_K3 <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
	ui_min = -2.0; ui_max = 2.0;
	ui_tooltip = "Adjust the Distortion K1, K2, & K3.\n"
				 "Default is 0.0";
	ui_label = " BD K1 K2 K3";
	ui_category = "Distortion Corrections";
> = float3(DC_X,DC_Y,DC_Z);

uniform float Zoom <
	ui_type = "drag";
	ui_min = -0.5; ui_max = 0.5;
	ui_label = " BD Zoom";
	ui_category = "Distortion Corrections";
> = DC_W;
#else
	#if DC
	uniform bool BD_Options <
		ui_label = "·Toggle Barrel Distortion·";
		ui_tooltip = "Use this if you modded the game to remove Barrel Distortion.";
		ui_category = "Distortion Corrections";
	> = !true;
	#else
		static const int BD_Options = 1;
	#endif
static const float3 Colors_K1_K2_K3 = float3(DC_X,DC_Y,DC_Z);
static const float Zoom = DC_W;
#endif

#if !SuperDepth && !HelixVision
uniform int Barrel_Distortion <
	ui_type = "combo";
	ui_items = "Off\0Blinders A\0Blinders B\0";
	ui_label = "·Barrel Distortion·";
	ui_tooltip = "Use this to disable or enable Barrel Distortion A & B.\n"
				 "This also lets you select from two different Blinders.\n"
			     "Default is Blinders A.\n";
	ui_category = "Image Adjustment";
> = 0;

uniform float FoV <
	ui_type = "slider";
	ui_min = 0; ui_max = 0.5;
	ui_label = " Field of View";
	ui_tooltip = "Lets you adjust the FoV of the Image.\n"
				 "Default is 0.0.";
	ui_category = "Image Adjustment";
> = 0;

uniform float3 Polynomial_Colors_K1 <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = " Polynomial Distortion K1";
	ui_tooltip = "Adjust the Polynomial Distortion K1_Red, K1_Green, & K1_Blue.\n"
				 "Default is (R 0.22, G 0.22, B 0.22)";
	ui_category = "Image Adjustment";
> = float3(0.22, 0.22, 0.22);

uniform float3 Polynomial_Colors_K2 <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = " Polynomial Distortion K2";
	ui_tooltip = "Adjust the Polynomial Distortion K2_Red, K2_Green, & K2_Blue.\n"
				 "Default is (R 0.24, G 0.24, B 0.24)";
	ui_category = "Image Adjustment";
> = float3(0.24, 0.24, 0.24);

uniform bool Theater_Mode <
	ui_label = " Theater Mode";
	ui_tooltip = "Sets the VR Shader into Theater mode.";
	ui_category = "Image Adjustment";
> = false;
#else
static const int Barrel_Distortion = 0;
static const float FoV = 0;
static const float3 Polynomial_Colors_K1 = float3(0.22, 0.22, 0.22);
static const float3 Polynomial_Colors_K2 = float3(0.24, 0.24, 0.24);
static const int Theater_Mode = 0;
#endif

uniform float Blinders <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "·Blinders·";
	ui_tooltip = "Lets you adjust blinders sensitivity.\n"
				 "Default is Zero, Off.";
	ui_category = "Image Effects";
> = 0;

uniform float Adjust_Vignette <
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_label = " Vignette";
	ui_tooltip = "Soft edge effect around the image.";
	ui_category = "Image Effects";
> = 0.0;
#if !HelixVision //Removed because HelixVision_Mode Has Built in sharpening.
uniform float Sharpen_Power <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 5.0;
	ui_label = " SmartSharp";
	ui_tooltip = "Adjust this to clear up the image the game, movie picture & etc.\n"
				 "This is Smart Sharp Jr code based on the Main Smart Sharp shader.\n"
				 "It can be pushed more and looks better then the basic USM.";
	ui_category = "Image Effects";
> = 0;
#else
static const float Sharpen_Power = 0;
#endif
uniform float Saturation <
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_label = " Saturation";
	ui_tooltip = "Lets you saturate image, basically adds more color.";
	ui_category = "Image Effects";
> = 0;

#if !SuperDepth && !HelixVision
	uniform bool NCAOC < // Non Companion App Overlay Compatibility
	ui_label = " Alternative Overlay Mode";
	ui_tooltip = "Sets the VR Shader to Non Companion App Overlay Compatibility.\n"
				 "This lets the overlay work in other Desktop Mirroring software.";
	ui_category = "Extra Options";
> = false;
#else
	static const int NCAOC = 0;
#endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
uniform bool Cancel_Depth < source = "key"; keycode = Cancel_Depth_Key; toggle = true; mode = "toggle";>;
uniform bool Mask_Cycle < source = "key"; keycode = Mask_Cycle_Key; toggle = true; >;
uniform bool Text_Info < source = "key"; keycode = Text_Info_Key; toggle = true; mode = "toggle";>;
uniform bool CLK < source = "mousebutton"; keycode = Cursor_Lock_Key; toggle = true; mode = "toggle";>;
uniform bool Trigger_Fade_A < source = "mousebutton"; keycode = Fade_Key; toggle = true; mode = "toggle";>;
uniform bool Trigger_Fade_B < source = "mousebutton"; keycode = Fade_Key;>;
uniform bool overlay_open < source = "overlay_open"; >;
uniform float2 Mousecoords < source = "mousepoint"; > ;
uniform float frametime < source = "frametime";>;
uniform float timer < source = "timer"; >;

static const float Auto_Balance_Clamp = 0.5; //This Clamps Auto Balance's max Distance.

#if Compatibility_DD
uniform bool DepthCheck < source = "bufready_depth"; >;
#endif

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define Interpupillary_Distance IPD * pix.x
#define AI Interlace_Anaglyph.x * 0.5 //Optimization for line interlaced Adjustment.
#define Res float2(BUFFER_WIDTH, BUFFER_HEIGHT)

float fmod(float a, float b)
{
	float c = frac(abs(a / b)) * abs(b);
	return a < 0 ? -c : c;
}
///////////////////////////////////////////////////////////Conversions/////////////////////////////////////////////////////////////
float3 RGBtoYCbCr(float3 rgb) // For Super3D a new Stereo3D output.
{   float TCoRF[1];//The Chronicles of Riddick: Assault on Dark Athena FIX I don't know why it works.......
	float Y  =  .299 * rgb.x + .587 * rgb.y + .114 * rgb.z; // Luminance
	float Cb = -.169 * rgb.x - .331 * rgb.y + .500 * rgb.z; // Chrominance Blue
	float Cr =  .500 * rgb.x - .419 * rgb.y - .081 * rgb.z; // Chrominance Red
	return float3(Y,Cb + 128./255.,Cr + 128./255.);
}

#if SuperDepth //The Chronicles of Riddick: Assault on Dark Athena FIX I don't know why it works.......
float3 youknow(float2 Idontknow)
{
	float whatisgoing;
	float3 on;
	return  whatisgoing+on;
}
#endif
///////////////////////////////////////////////////////////////3D Starts Here/////////////////////////////////////////////////////////////////
texture DepthBufferTex : DEPTH;
sampler DepthBuffer
	{
		Texture = DepthBufferTex;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
		//Used Point for games like AMID Evil that don't have a proper Filtering.
		MagFilter = POINT;
		MinFilter = POINT;
		MipFilter = POINT;
	};

texture BackBufferTex : COLOR;

sampler BackBuffer
	{
		Texture = BackBufferTex;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};

sampler BackBufferCLAMP
	{
		Texture = BackBufferTex;
		AddressU = CLAMP;
		AddressV = CLAMP;
		AddressW = CLAMP;
	};
#if D_Frame || DF
texture texCF { Width = BUFFER_WIDTH ; Height = BUFFER_HEIGHT ; Format = RGBA8; };

sampler SamplerCF
	{
		Texture = texCF;
	};

texture texDF { Width = BUFFER_WIDTH ; Height = BUFFER_HEIGHT ; Format = RGBA8; };

sampler SamplerDF
	{
		Texture = texDF;
	};
#endif
texture texDMVR  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; MipLevels = 6;};

sampler SamplerDMVR
	{
		Texture = texDMVR;
	};

texture texzBufferVR  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
//not doing mips here?
sampler SamplerzBufferVR
	{
		Texture = texzBufferVR;
		AddressU = MIRROR;
		AddressV = MIRROR;
		AddressW = MIRROR;
	};

#if UI_MASK
texture TexMaskA < source = "DM_Mask_A.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerMaskA { Texture = TexMaskA;};
texture TexMaskB < source = "DM_Mask_B.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerMaskB { Texture = TexMaskB;};
#endif
//////////////////////////////////////////////////////////Stored Textures/////////////////////////////////////////////////////////////////////
texture texPBVR  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };

sampler SamplerPBBVR
	{
		Texture = texPBVR;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};
///////////////////////////////////////////////////////Left Right Textures////////////////////////////////////////////////////////////////////
#if BUFFER_COLOR_BIT_DEPTH == 10 //This PreProcessor is not a bool it really is 8 or 10.
	#define RGBA RGB10A2
#else
	#define RGBA RGBA8
#endif

#if Compatibility_DD
#define RGBAC RGB10A2
#else
#define RGBAC RGBA8
#endif

#if HelixVision
texture DoubleTex  { Width = BUFFER_WIDTH * 2; Height = BUFFER_HEIGHT; Format = RGBA; };

sampler SamplerDouble
	{
		Texture = DoubleTex;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};
#else
texture LeftTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBAC; };

sampler SamplerLeft
	{
		Texture = LeftTex;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};

texture RightTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBAC; };

sampler SamplerRight
	{
		Texture = RightTex;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};
#endif
////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////
texture texLumVR {Width = 256*0.5; Height = 256*0.5; Format = RGBA16F; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1

sampler SamplerLumVR
	{
		Texture = texLumVR;
	};

texture texOtherVR {Width = 256*0.5; Height = 256*0.5; Format = RG16F; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1

sampler SamplerOtherVR
	{
		Texture = texOtherVR;
	};


float2 Lum(float2 texcoord)
	{   //Luminance
		return saturate(tex2Dlod(SamplerLumVR,float4(texcoord,0,11)).xy);//Average Luminance Texture Sample
	}
////////////////////////////////////////////////////Distortion Correction//////////////////////////////////////////////////////////////////////
#if BD_Correction || DC
float2 D(float2 p, float k1, float k2, float k3) //Lens + Radial lens undistort filtering Left & Right
{   // Normalize the u,v coordinates in the range [-1;+1]
	p = (2. * p - 1.);
	// Calculate Zoom
	p *= 1 + Zoom;
	// Calculate l2 norm
	float r2 = p.x*p.x + p.y*p.y;
	float r4 = r2 * r2;
	float r6 = r4 * r2;
	// Forward transform
	float x2 = p.x * (1. + k1 * r2 + k2 * r4 + k3 * r6);
	float y2 = p.y * (1. + k1 * r2 + k2 * r4 + k3 * r6);
	// De-normalize to the original range
	p.x = (x2 + 1.) * 1. * 0.5;
	p.y = (y2 + 1.) * 1. * 0.5;

return p;
}
#endif
///////////////////////////////////////////////////////////3D Image Adjustments/////////////////////////////////////////////////////////////////////
#if D_Frame || DF
float4 CurrentFrame(in float4 position : SV_Position, in float2 texcoords : TEXCOORD) : SV_Target
{
		return tex2Dlod(BackBufferCLAMP,float4(texcoords,0,0));
}

float4 DelayFrame(in float4 position : SV_Position, in float2 texcoords : TEXCOORD) : SV_Target
{
	return tex2Dlod(SamplerCF,float4(texcoords,0,0));
}

float4 CSB(float2 texcoords)
{
	if(Depth_Map_View == 0)
		return tex2Dlod(SamplerDF,float4(texcoords,0,0));
	else
		return tex2D(SamplerzBufferVR,texcoords).xxxx;
}
#else
float4 CSB(float2 texcoords)
{   //Cal Basic Vignette
	float2 TC = -texcoords * texcoords*32 + texcoords*32;
	float WTF_Fable = 0.00000000000001;
	if(!Depth_Map_View)
		return tex2Dlod(BackBuffer,float4(texcoords,0,0)) * smoothstep(WTF_Fable,(WTF_Fable+Adjust_Vignette)*27.0f,TC.x * TC.y) ;
	else
		return tex2Dlod(SamplerzBufferVR,float4(texcoords,0,0)).xxxx;
}
#endif

#if LBC || LBM || LB_Correction || LetterBox_Masking
float LBDetection()
{   //0.120 0.879
	if ( LetterBox_Masking >= 3 )
		return (CSB(float2(0.1,0.5)) == 0) && (CSB(float2(0.9,0.5)) == 0) && (CSB(float2(0.5,0.5)) > 0) ? 1 : 0;
	else     //Center_Top                 //Bottom_Left                //Center
		return (CSB(float2(0.5,0.1)) == 0) && (CSB(float2(0.1,0.9)) == 0) && (CSB(float2(0.5,0.5)) > 0) ? 1 : 0;
}
#endif

#if SDT || SD_Trigger
float TargetedDepth(float2 TC)
{
	return smoothstep(0,1,tex2Dlod(SamplerzBufferVR,float4(TC,0,0)).y);
}

float SDTriggers()//Specialized Depth Triggers
{   float Threshold = 0.001;//Both this and the options below may need to be adjusted. A Value lower then 7.5 will break this.!?!?!?!
	if ( SD_Trigger == 1 || SDT == 1)//Top _ Left                             //Center_Left                             //Botto_Left
		return (TargetedDepth(float2(0.95,0.25)) >= Threshold ) && (TargetedDepth(float2(0.95,0.5)) >= Threshold) && (TargetedDepth(float2(0.95,0.75)) >= Threshold) ? 0 : 1;
	else
		return 0;
}
#endif
/////////////////////////////////////////////////////////////Cursor///////////////////////////////////////////////////////////////////////////
float4 MouseCursor(float2 texcoord )
{   float4 Out = CSB(texcoord),Color;
		float A = 0.959375, TCoRF = 1-A, Cursor;
		if(Cursor_Type > 0)
		{
			float CCA = 0.005, CCB = 0.00025, CCC = 0.25, CCD = 0.00125, Arrow_Size_A = 0.7, Arrow_Size_B = 1.3, Arrow_Size_C = 4.0;//scaling
			float2 MousecoordsXY = Mousecoords * pix, center = texcoord, Screen_Ratio = float2(1.75,1.0), Size_Color = float2(1+Cursor_SC.x,Cursor_SC.y);
			float THICC = (2.0+Size_Color.x) * CCB, Size = Size_Color.x * CCA, Size_Cubed = (Size_Color.x*Size_Color.x) * CCD;

			if (Cursor_Lock && !CLK)
			MousecoordsXY = float2(0.5,0.5);
			if (Cursor_Type == 3)
			Screen_Ratio = float2(1.6,1.0);

			float4 Dist_from_Hori_Vert = float4( abs((center.x - (Size* Arrow_Size_B) / Screen_Ratio.x) - MousecoordsXY.x) * Screen_Ratio.x, // S_dist_fromHorizontal
												 abs(center.x - MousecoordsXY.x) * Screen_Ratio.x, 										  // dist_fromHorizontal
												 abs((center.y - (Size* Arrow_Size_B)) - MousecoordsXY.y),								   // S_dist_fromVertical
												 abs(center.y - MousecoordsXY.y));														   // dist_fromVertical

			//Cross Cursor
			float B = min(max(THICC - Dist_from_Hori_Vert.y,0),max(Size-Dist_from_Hori_Vert.w,0)), A = min(max(THICC - Dist_from_Hori_Vert.w,0),max(Size-Dist_from_Hori_Vert.y,0));
			float CC = A+B; //Cross Cursor

			//Solid Square Cursor
			float SSC = min(max(Size_Cubed - Dist_from_Hori_Vert.y,0),max(Size_Cubed-Dist_from_Hori_Vert.w,0)); //Solid Square Cursor

			if (Cursor_Type == 3)
			{
				Dist_from_Hori_Vert.y = abs((center.x - Size / Screen_Ratio.x) - MousecoordsXY.x) * Screen_Ratio.x ;
				Dist_from_Hori_Vert.w = abs(center.y - Size - MousecoordsXY.y);
			}
			//Cursor
			float C = all(min(max(Size - Dist_from_Hori_Vert.y,0),max(Size - Dist_from_Hori_Vert.w,0)));//removing the line below removes the square.
				  C -= all(min(max(Size - Dist_from_Hori_Vert.y * Arrow_Size_C,0),max(Size - Dist_from_Hori_Vert.w * Arrow_Size_C,0)));//Need to add this to fix a - bool issue in openGL
				  C -= all(min(max((Size * Arrow_Size_A) - Dist_from_Hori_Vert.x,0),max((Size * Arrow_Size_A)-Dist_from_Hori_Vert.z,0)));			// Cursor Array //
			// Cursor Array //
			if(Cursor_Type == 1)
				Cursor = CC;
			else if (Cursor_Type == 2)
				Cursor = SSC;
			else if (Cursor_Type == 3)
				Cursor = C;

			// Cursor Color Array //
			float3 CCArray[11] = {
			float3(1,1,1),//White
			float3(0,0,1),//Blue
			float3(0,1,0),//Green
			float3(1,0,0),//Red
			float3(1,0,1),//Magenta
			float3(0,1,1),
			float3(1,1,0),
			float3(1,0.4,0.7),
			float3(1,0.64,0),
			float3(0.5,0,0.5),
			float3(0,0,0) //Black
			};
			int CSTT = clamp(Cursor_SC.y,0,10);
			Color.rgb = CCArray[CSTT];
		}

return Cursor ? Color : Out;
}
//////////////////////////////////////////////////////////Depth Map Information/////////////////////////////////////////////////////////////////////
float DMA() //Small List of internal Multi Game Depth Adjustments.
{ float DMA = Depth_Map_Adjust;
	#if (__APPLICATION__ == 0xC0052CC4) //Halo The Master Chief Collection
	if( WP == 4) // Change on weapon selection.
		DMA *= 0.25;
	else if( WP == 5)
		DMA *= 0.8875;
	#endif
	return DMA;
}

float2 TC_SP(float2 texcoord)
{
	#if BD_Correction || DC
	if(BD_Options == 0 || BD_Options == 2)
	{
		float3 K123 = Colors_K1_K2_K3 * 0.1;
		texcoord = D(texcoord.xy,K123.x,K123.y,K123.z);
	}
	#endif
	#if DB_Size_Position || SP || LBC || LB_Correction || SDT || SD_Trigger

		#if SDT || SD_Trigger
			float2 X_Y = float2(Image_Position_Adjust.x,Image_Position_Adjust.y) + float2(SDTriggers() ? -0.190 : 0 , 0);
		#else
			float2 X_Y = float2(Image_Position_Adjust.x,Image_Position_Adjust.y);
		#endif

	texcoord.xy += float2(-X_Y.x,X_Y.y)*0.5;

		#if LBC || LB_Correction
			float2 H_V = Horizontal_and_Vertical * float2(1,LBDetection() ? 1.315 : 1 );
		#else
			float2 H_V = Horizontal_and_Vertical;
		#endif
	float2 midHV = (H_V-1) * float2(BUFFER_WIDTH * 0.5,BUFFER_HEIGHT * 0.5) * pix;
	texcoord = float2((texcoord.x*H_V.x)-midHV.x,(texcoord.y*H_V.y)-midHV.y);
	#endif
	return texcoord;
}
/* Not needed Yet may add it in later. If I feel like it.
float Log_DB(float DB)
{
	const float C = 0.01;
	// RESHADE LOGARITHMIC DEPTH FUNCTIONS FROM RESHADE.FXH
	zBuffer = (exp(zBuffer * log(C + 1.0)) - 1.0) / C;
}
*/
float Depth(float2 texcoord)
{
	//Conversions to linear space.....
	float zBuffer = tex2Dlod(DepthBuffer, float4(texcoord,0,0)).x, Far = 1.0, Near = 0.125/DMA(); //Near & Far Adjustment

	//Man Why can't depth buffers Just Be Normal
	float2 C = float2( Far / Near, 1.0 - Far / Near ), Z = Offset < 0 ? min( 1.0, zBuffer * ( 1.0 + abs(Offset) ) ) : float2( zBuffer, 1.0 - zBuffer );

	if(Offset > 0 || Offset < 0)
		Z = Offset < 0 ? float2( Z.x, 1.0 - Z.y ) : min( 1.0, float2( Z.x * (1.0 + Offset) , Z.y / (1.0 - Offset) ) );
	//MAD - RCP
	if (Depth_Map == 0) //DM0 Normal
		zBuffer = rcp(Z.x * C.y + C.x);
	else if (Depth_Map == 1) //DM1 Reverse
		zBuffer = rcp(Z.y * C.y + C.x);
	return saturate(zBuffer);
}

float2 WeaponDepth(float2 texcoord)
{
	//Weapon Setting//
	float3 WA_XYZ = Weapon_Adjust;
	#if WSM >= 1
		WA_XYZ = Weapon_Profiles(WP, Weapon_Adjust);
	#endif
	//Conversions to linear space.....
	float zBufferWH = tex2Dlod(DepthBuffer, float4(texcoord,0,0)).x, Far = 1.0, Near = 0.125/WA_XYZ.y;  //Near & Far Adjustment

	float2 Offsets = float2(1 + WA_XYZ.z,1 - WA_XYZ.z), Z = float2( zBufferWH, 1-zBufferWH );

	if (WA_XYZ.z > 0)
	Z = min( 1, float2( Z.x * Offsets.x , Z.y / Offsets.y  ));

	[branch] if (Depth_Map == 0)//DM0. Normal
		zBufferWH = Far * Near / (Far + Z.x * (Near - Far));
	else if (Depth_Map == 1)//DM1. Reverse
		zBufferWH = Far * Near / (Far + Z.y * (Near - Far));

	return float2(saturate(zBufferWH), WA_XYZ.x);
}
//3x2 and 2x3 not supported on older ReShade versions. I had to use 3x3. Old Values for 3x2
float3x3 PrepDepth(float2 texcoord)//[0][0] = R | [0][1] = G | [1][0] = B //[1][1] = A | [2][0] = D | [2][1] = DM
{
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
	float4 DM = Depth(TC_SP(texcoord)).xxxx;
	float R, G, B, A, WD = WeaponDepth(TC_SP(texcoord)).x, CoP = WeaponDepth(TC_SP(texcoord)).y, CutOFFCal = (CoP/DMA()) * 0.5; //Weapon Cutoff Calculation
	CutOFFCal = step(DM.x,CutOFFCal);

	[branch] if (WP == 0)
		DM.x = DM.x;
	else
	{
		DM.x = lerp(DM.x,WD,CutOFFCal);
		DM.y = lerp(0.0,WD,CutOFFCal);
		DM.z = lerp(0.5,WD,CutOFFCal);
	}

	R = DM.x; //Mix Depth
	G = DM.y > saturate(smoothstep(0,2.5,DM.w)); //Weapon Mask
	B = DM.z; //Weapon Hand
	A = ZPD_Boundary == 3 || ZPD_Boundary == 4 ? max( G, R) : R; //Grid Depth
	//[0][0] = R | [0][1] = G | [0][2] = B //[1][0] = A | [1][1] = D | [1][2] = DM // [2][0] = Null | [2][1] = Null | [2][2] = Null
	return float3x3( saturate(float3(R, G, B)) , saturate(float3(A,Depth(SDT || SD_Trigger ? texcoord : TC_SP(texcoord)).x,DM.w)) , float3(0,0,0) );
}
//////////////////////////////////////////////////////////////Depth HUD Alterations///////////////////////////////////////////////////////////////////////
#if UI_MASK
float HUD_Mask(float2 texcoord )
{   float Mask_Tex;
	    if (Mask_Cycle == 1)
	        Mask_Tex = tex2Dlod(SamplerMaskB,float4(texcoord.xy,0,0)).a;
	    else
	        Mask_Tex = tex2Dlod(SamplerMaskA,float4(texcoord.xy,0,0)).a;

	return saturate(Mask_Tex);
}
#endif
/////////////////////////////////////////////////////////Fade In and Out Toggle/////////////////////////////////////////////////////////////////////
float Fade_in_out(float2 texcoord)
{ float Trigger_Fade, AA = Fade_Time_Adjust, PStoredfade = tex2D(SamplerLumVR,float2(0.25,0.5)).z;
	if(Eye_Fade_Reduction_n_Power.z == 0)
		AA *= 0.5;
	else if(Eye_Fade_Reduction_n_Power.z == 2)
		AA *= 1.5;
	//Fade in toggle.
	if(FPSDFIO == 1)
		Trigger_Fade = Trigger_Fade_A;
	else if(FPSDFIO == 2)
		Trigger_Fade = Trigger_Fade_B;

	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp(-frametime/((1-AA)*1000))); ///exp2 would be even slower
}

float Z_Boundary(){return ZPD_Boundary ;};

float Fade(float2 texcoord)//Check Depth
{
	float CD, Detect;
	//So this spacing allows for.........
	//The Chronicles of Riddick: Assault on Dark Athena.
	//Too Work............................................. WTF
	if(Z_Boundary() > 0)
	{   //Normal A & B for both
		float CDArray_A[7] = { 0.125 ,0.25, 0.375,0.5, 0.625, 0.75, 0.875}, CDArray_B[7] = { 0.25 ,0.375, 0.4375, 0.5, 0.5625, 0.625, 0.75};
		float CDArrayZPD_A[7] = { ZPD_Separation.x * 0.625, ZPD_Separation.x * 0.75, ZPD_Separation.x * 0.875, ZPD_Separation.x, ZPD_Separation.x * 0.875, ZPD_Separation.x * 0.75, ZPD_Separation.x * 0.625 },
			  CDArrayZPD_B[7] = { ZPD_Separation.x * 0.3, ZPD_Separation.x * 0.5, ZPD_Separation.x * 0.75, ZPD_Separation.x, ZPD_Separation.x * 0.75, ZPD_Separation.x * 0.5, ZPD_Separation.x * 0.3};
		float2 GridXY;
		//Screen Space Detector 7x7 Grid from between 0 to 1 and ZPD Detection becomes stronger as it gets closer to the Center.
		[loop]
		for( int i = 0 ; i < 7; i++ )
		{
			for( int j = 0 ; j < 7; j++ )
			{
				if(ZPD_Boundary == 1)
					GridXY = float2( CDArray_A[i], CDArray_A[j]);
				else if(ZPD_Boundary == 2 || ZPD_Boundary == 4)
					GridXY = float2( CDArray_B[i], CDArray_A[j]);
				else if(ZPD_Boundary == 3)
					GridXY = float2( CDArray_A[i], CDArray_B[j]);

				float ZPD_I = ZPD_Boundary == 2 || ZPD_Boundary == 4  ? CDArrayZPD_B[i] : CDArrayZPD_A[i] ;

				if(ZPD_Boundary == 3 || ZPD_Boundary == 4)
				{
					if ( PrepDepth(GridXY)[1][0] == 1 )
						ZPD_I = 0;
				}
				// CDArrayZPD[i] reads across prepDepth.......
				CD = 1 - ZPD_I / PrepDepth(GridXY)[1][0];

				#if UI_MASK
					CD = max( 1 - ZPD_I / HUD_Mask(GridXY), CD );
				#endif
				if ( CD < -DG_W )//may lower this to like -0.1
					Detect = 1;
			}
		}
	}
	float Trigger_Fade = Detect, AA = (1-(ZPD_Boundary_n_Fade.y*2.))*1000, PStoredfade = tex2Dlod(SamplerLumVR,float4(float2(0.75,0.5),0,0)).z;
	//Fade in toggle.
	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp(-frametime/AA)); ///exp2 would be even slower
}

float Motion_Blinders(float2 texcoord)
{   float Trigger_Fade = tex2Dlod(SamplerOtherVR,float4(texcoord,0,11)).x * lerp(0.0,25.0,Blinders), AA = (1-Fade_Time_Adjust)*1000, PStoredfade = tex2D(SamplerOtherVR,texcoord - 1).y;
	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp2(-frametime/AA)); ///exp2 would be even slower
}
//////////////////////////////////////////////////////////Depth Map Alterations/////////////////////////////////////////////////////////////////////

float4 DepthMap(in float4 position : SV_Position,in float2 texcoord : TEXCOORD) : SV_Target
{
	float4 DM = float4(PrepDepth(texcoord)[0][0],PrepDepth(texcoord)[0][1],PrepDepth(texcoord)[0][2],PrepDepth(texcoord)[1][1]);
	float R = DM.x, G = DM.y, B = DM.z, Auto_Scale =  WZPD_and_WND.y > 0.0 ? smoothstep(0,1,PrepDepth(0.5f)[0][0]) : 1;

	//Fade Storage
	float ScaleND = lerp(R,1,smoothstep(min(-WZPD_and_WND.y,-WZPD_and_WND.z * Auto_Scale),1,R));

	if (WZPD_and_WND.y > 0)
		R = lerp(ScaleND,R,smoothstep(0,0.25,ScaleND));

	if(texcoord.x < pix.x * 2 && texcoord.y < pix.y * 2)
		R = Fade_in_out(texcoord);
	if(1-texcoord.x < pix.x * 2 && 1-texcoord.y < pix.y * 2)
		R = Fade(texcoord);
	if(texcoord.x < pix.x * 2 && 1-texcoord.y < pix.y * 2)//BL
		R = Motion_Blinders(texcoord);

	float Luma_Map = dot(0.333, tex2D(BackBufferCLAMP,texcoord).rgb);

	return saturate(float4(R,G,B,Luma_Map));
}

float AutoDepthRange(float d, float2 texcoord )
{ float LumAdjust_ADR = smoothstep(-0.0175,Auto_Depth_Adjust,Lum(texcoord).y);
	if (RE)
		LumAdjust_ADR = smoothstep(-0.0175,Auto_Depth_Adjust,Lum(texcoord).x);

    return min(1,( d - 0 ) / ( LumAdjust_ADR - 0));
}
#if RE_Fix || RE
float AutoZPDRange(float ZPD, float2 texcoord )
{   //Adjusted to only effect really intense differences.
	float LumAdjust_AZDPR = smoothstep(-0.0175,0.1875,Lum(texcoord).y);
	if(RE_Fix == 2 || RE == 2)
		LumAdjust_AZDPR = smoothstep(0,0.075,Lum(texcoord).y);
    return saturate(LumAdjust_AZDPR * ZPD);
}
#endif
float2 Conv(float D,float2 texcoord)
{	float Z = ZPD_Separation.x, WZP = 0.5, ZP = 0.5, ALC = abs(Lum(texcoord).x), W_Convergence = WZPD_and_WND.x, WZPDB, Distance_From_Bottom = 0.9375;
    //Screen Space Detector.
	if (abs(Weapon_ZPD_Boundary) > 0)
	{   float WArray[8] = { 0.5, 0.5625, 0.625, 0.6875, 0.75, 0.8125, 0.875, 0.9375};
		float MWArray[8] = { 0.4375, 0.46875, 0.5, 0.53125, 0.625, 0.75, 0.875, 0.9375};
		float WZDPArray[8] = { 1.0, 0.5, 0.75, 0.5, 0.625, 0.5, 0.55, 0.5};//SoF ZPD Weapon Map
		[unroll] //only really only need to check one point just above the center bottom and to the right.
		for( int i = 0 ; i < 8; i++ )
		{
			if(WP == 22 || WP == 4)//SoF & BL 2
				WZPDB = 1 - (WZPD_and_WND.x * WZDPArray[i]) / tex2Dlod(SamplerDMVR,float4(float2(WArray[i],0.9375),0,0)).z;
			else
			{
				if (Weapon_ZPD_Boundary < 0) //Code for Moving Weapon Hand stablity.
					WZPDB = 1 - WZPD_and_WND.x / tex2Dlod(SamplerDMVR,float4(float2(MWArray[i],Distance_From_Bottom),0,0)).z;
				else //Normal
					WZPDB = 1 - WZPD_and_WND.x / tex2Dlod(SamplerDMVR,float4(float2(WArray[i],Distance_From_Bottom),0,0)).z;
			}

			if (WZPDB < -0.1)
				W_Convergence *= 1.0-abs(Weapon_ZPD_Boundary);
		}
	}

	W_Convergence = 1 - W_Convergence / D;
	float WD = D; //Needed to seperate Depth for the  Weapon Hand. It was causing problems with Auto Depth Range below.

	#if RE_Fix || RE
		Z = AutoZPDRange(Z,texcoord);
	#endif
		if (Auto_Depth_Adjust > 0)
			D = AutoDepthRange(D,texcoord);

	#if Balance_Mode || BM
			ZP = saturate(ZPD_Balance);
	#else
		if(Auto_Balance_Ex > 0 )
			ZP = saturate(ALC);
	#endif
		Z *= lerp( 1, ZPD_Boundary_n_Fade.x, smoothstep(0,1,tex2Dlod(SamplerLumVR,float4(float2(0.75,0.5),0,0)).z));
		float Convergence = 1 - Z / D;
		if (ZPD_Separation.x == 0)
			ZP = 1;

		if (WZPD_and_WND.x <= 0)
			WZP = 1;

		if (ALC <= 0.025)
			WZP = 1;

		ZP = min(ZP,Auto_Balance_Clamp);

		float Separation = lerp(1.0,5.0,ZPD_Separation.y);
    return float2(lerp(Separation * Convergence,min(saturate(Max_Depth),D), ZP),lerp(W_Convergence,WD,WZP));
}

float2 DB( float2 texcoord)
{
	// X = Mix Depth | Y = Weapon Mask | Z = Weapon Hand | W = Normal Depth
	float4 DM = float4(tex2Dlod(SamplerDMVR,float4(texcoord,0,0)).xyz,PrepDepth(texcoord)[1][1]);
	//Hide Temporal passthrough
	if(texcoord.x < pix.x * 2 && texcoord.y < pix.y * 2)
		DM = PrepDepth(texcoord)[0][0];
	if(1-texcoord.x < pix.x * 2 && 1-texcoord.y < pix.y * 2)
		DM = PrepDepth(texcoord)[0][0];

	if (WP == 0 || WZPD_and_WND.x <= 0)
		DM.y = 0;
	//Handle Convergence Here
	DM.y = lerp(Conv(DM.x,texcoord).x, Conv(DM.z,texcoord).y, DM.y);
	//Better mixing for eye Comfort
	DM.z = DM.y;
	DM.y += lerp(DM.y,DM.x,DM.w);
	DM.y *= 0.5f;
	DM.y = lerp(DM.y,DM.z,0.6875f);

	if (Depth_Detection == 1)
	{
		if (!DepthCheck)
			DM = 0.0625;
	}

	if (Cancel_Depth)
		DM = 0.0625;

	#if Invert_Depth || ID
		DM.y = 1 - DM.y;
	#endif

	#if UI_MASK
		DM.y = lerp(DM.y,0,step(1.0-HUD_Mask(texcoord),0.5));
	#endif

	if(LBM || LetterBox_Masking)
	{
		float storeDM = DM.y;
	if ( LBM >= 3 || LetterBox_Masking >= 3 )
		DM.y = texcoord.x > 0.125 && texcoord.x < 0.875 ? storeDM : 0.0125;//DM.y = texcoord.x > 0.051 && texcoord.x < 0.949 ? storeDM : 0.0125;
	else
		DM.y = texcoord.y > 0.120 && texcoord.y < 0.879 ? storeDM : 0.0125;

	#if LBM || LetterBox_Masking
		if((LBM == 2 || LBM == 4 || LetterBox_Masking == 2 || LetterBox_Masking == 4) && !LBDetection())
			DM.y = storeDM;
	#endif
	}

	return float2(DM.y,DM.w);
}
////////////////////////////////////////////////////Depth & Special Depth Triggers//////////////////////////////////////////////////////////////////
float2 zBuffer(in float4 position : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
	return DB( texcoord.xy ).xy;
}

float2 GetDB(float2 texcoord, float Mips)
{
	float Scale_Depth = tex2Dlod(SamplerzBufferVR, float4(texcoord,0, Mips) ).x;
	return Scale_Depth;//lerp(Scale_Depth,-Scale_Depth,-ZPD_Separation.x); //Save for AI Shader
}
//Perf Level selection left one open for one more view mode.
#define Normal_View 0.025
static const float4 Performance_LvL[3] = { float4( 0.5, 0.5, 0.679, 0.0 ), float4( 1.0, 1.0, 1.425, 0.0), float4( 1.5, 1.5, 2.752, 0.0 ) };
static const float4 Performance_Adj[3] = { float4( 0.0, 0.527, 0.0, 0.0 ), float4( 0.0, 0.04, 0.0, 0.0), float4( 0.0, 0.557, 0.0, 0.0 ) }; //X0.5 | 0.0 |-0.5 
//////////////////////////////////////////////////////////Parallax Generation///////////////////////////////////////////////////////////////////////
float2 Parallax(float Diverge, float2 Coordinates) // Horizontal parallax offset & Hole filling effect
{   float Perf = Performance_LvL[Performance_Level].x, MS = Diverge * pix.x, GetDepth = smoothstep(0,1,GetDB(Coordinates, 1).x),
				 Near_Far_CB_Size =  View_Mode == 3 ? 1.0 : GetDepth >= 0.5 ? 1.0 : 0.5, VM_Adj = Performance_Adj[Performance_Level].x,
				 Offset_Adjust[5] = { -Normal_View, 0.5, 0.5, 0.5, 0.0};
	float2 ParallaxCoord = Coordinates, CBxy = floor( float2(Coordinates.x * BUFFER_WIDTH, Coordinates.y * BUFFER_HEIGHT) * Near_Far_CB_Size );
	//Would Use Switch....
	if( View_Mode == 1)
	{
		VM_Adj = Performance_Adj[Performance_Level].y;
		Perf = Performance_LvL[Performance_Level].y;
	}
	if( View_Mode == 2)
		Perf = Performance_LvL[Performance_Level].z;
	if( View_Mode == 3)
	{
		if( GetDepth >= 0.999 )
		{
			VM_Adj = fmod(CBxy.x+CBxy.y,2) ? 0.0 : 0.527;
			Perf = fmod(CBxy.x+CBxy.y,2) ? 0.679 : 0.5;
		}
		else if( GetDepth >= 0.875)
		{
			VM_Adj = fmod(CBxy.x+CBxy.y,2) ? 0.557 : 0.0;
			Perf = fmod(CBxy.x+CBxy.y,2) ? 1.02 : 0.679;
		}
		else
		{
			VM_Adj = fmod(CBxy.x+CBxy.y,2) ? 0.0 : 0.04;
			Perf = fmod(CBxy.x+CBxy.y,2) ? 0.679 : 1.0;
		}
	} //VM_Adj = 0.04; Perf = fmod(CBxy.x+CBxy.y,2) ? 0.679 : 1.02 ; //Droped View Mode settins	
	/*
	float Cut_Out = step( 0.999, GetDepth), Luma_Adptive = lerp(0.5,1.0,smoothstep(0,1,tex2Dlod(SamplerDMSL,float4(Coordinates,0,5)).w * 0.5f) );
	if(L_VRS)
		Perf *= lerp(Luma_Adptive, 0.5, Cut_Out); 
	*/
	//ParallaxSteps Calculations
	float D = abs(Diverge), Cal_Steps = (D * Perf) + (D * VM_Adj), Steps = clamp( Cal_Steps, 0, 256 );//Foveated Rendering Point on attack 16-256 limit samples.
	// Offset per step progress & Limit
	float LayerDepth = rcp(Steps), TP = View_Mode == 0 ? Normal_View : lerp(0.03,0.04,GetDepth);//0.035
	//Offsets listed here Max Seperation is 3% - 8% of screen space with Depth Offsets & Netto layer offset change based on MS.
	float deltaCoordinates = MS * LayerDepth, CurrentDepthMapValue = GetDB(ParallaxCoord, 0).x, CurrentLayerDepth = 0.0f;
	float2 DB_Offset = float2(Diverge * TP, 0) * pix, Store_DB_Offset = DB_Offset;

    if( View_Mode >= 1 )
    	DB_Offset = 0;

	[loop] //Steep parallax mapping
	while ( CurrentDepthMapValue > CurrentLayerDepth )
	{   // Shift coordinates horizontally in linear fasion
	    ParallaxCoord.x -= deltaCoordinates;
	    // Get depth value at current coordinates
	    CurrentDepthMapValue = GetDB(float2(ParallaxCoord - DB_Offset), 0).x;
	    // Get depth of next layer
	    CurrentLayerDepth += LayerDepth;
		continue;
	}
	//Anti-Weapon Hand Fighting
	float Weapon_Mask = tex2Dlod(SamplerDMVR,float4(Coordinates,0,0)).y, ZFighting_Mask = 1.0-(1.0-tex2Dlod(SamplerDMVR,float4(Coordinates,0,5.4)).y - Weapon_Mask);
		  ZFighting_Mask = ZFighting_Mask * (1.0-Weapon_Mask);
	float Get_DB = GetDB(ParallaxCoord , 0).y, Get_DB_ZDP = WP > 0 ? lerp(Get_DB, abs(Get_DB), ZFighting_Mask) : Get_DB;
	// Parallax Occlusion Mapping
	float2 PrevParallaxCoord = float2(ParallaxCoord.x + deltaCoordinates, ParallaxCoord.y);
	float beforeDepthValue = Get_DB_ZDP, afterDepthValue = CurrentDepthMapValue - CurrentLayerDepth;
		  beforeDepthValue += LayerDepth - CurrentLayerDepth;
	// Depth Diffrence for Gap masking and depth scaling in Normal Mode.
	float depthDiffrence = afterDepthValue-beforeDepthValue, VM_Switch = View_Mode == 0 ? 0.025 : 1.0;
	// Interpolate coordinates
	float weight = afterDepthValue / min(-0.003,depthDiffrence);
		  ParallaxCoord = PrevParallaxCoord * weight + ParallaxCoord * (1.0f - weight);
	//This is to limit artifacts.
		ParallaxCoord += Store_DB_Offset * Offset_Adjust[View_Mode];
	// Apply gap masking
		ParallaxCoord.x -= depthDiffrence * MS * VM_Switch;

	return ParallaxCoord;
}
//////////////////////////////////////////////////////////////HUD Alterations///////////////////////////////////////////////////////////////////////
#if HUD_MODE || HM
float3 HUD(float3 HUD, float2 texcoord )
{
	float Mask_Tex, CutOFFCal = ((HUD_Adjust.x * 0.5)/DMA()) * 0.5, COC = step(PrepDepth(texcoord)[1][2],CutOFFCal); //HUD Cutoff Calculation
	//This code is for hud segregation.
	if (HUD_Adjust.x > 0)
		HUD = COC > 0 ? tex2D(BackBufferCLAMP,texcoord).rgb : HUD;

	#if UI_MASK
	    if (Mask_Cycle == true)
	        Mask_Tex = tex2Dlod(SamplerMaskB,float4(texcoord.xy,0,0)).a;
	    else
	        Mask_Tex = tex2Dlod(SamplerMaskA,float4(texcoord.xy,0,0)).a;

		float MAC = step(1.0-Mask_Tex,0.5); //Mask Adjustment Calculation
		//This code is for hud segregation.
		HUD = MAC > 0 ? tex2D(BackBufferCLAMP,texcoord).rgb : HUD;
	#endif
	return HUD;
}
#endif
///////////////////////////////////////////////////////////Stereo Calculation///////////////////////////////////////////////////////////////////////
float4 saturation(float4 C)
{
  float greyscale = dot(C.rgb, float3(0.2125, 0.7154, 0.0721));
   return lerp(greyscale.xxxx, C, (Saturation + 1.0));
}

#if HelixVision
void LR_Out(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 Double : SV_Target0)
#else
void LR_Out(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 Left : SV_Target0, out float4 Right : SV_Target1)//, out float StoreBB : SV_Target2)
#endif
{   float2 StoreTC = texcoord; //StoreBB = dot(tex2D(BackBufferCLAMP,texcoord).rgb,float3(0.2125, 0.7154, 0.0721));
	//Field of View
	float fov = FoV-(FoV*0.2), F = -fov + 1,HA = (F - 1)*(BUFFER_WIDTH*0.5)*pix.x;
	//Field of View Application
	float2 Z_A = float2(1.0,1.0); //Theater Mode
	if(!Theater_Mode)
	{
		Z_A = float2(1.0,0.5); //Full Screen Mode
		texcoord.x = (texcoord.x*F)-HA;
	}
	//Texture Zoom & Aspect Ratio//
	float X = Z_A.x;
	float Y = Z_A.y * Z_A.x * 2;
	float midW = (X - 1)*(BUFFER_WIDTH*0.5)*pix.x;
	float midH = (Y - 1)*(BUFFER_HEIGHT*0.5)*pix.y;

	texcoord = float2((texcoord.x*X)-midW,(texcoord.y*Y)-midH);
	//Store Texcoords for left and right eye
	float2 TCL = texcoord,TCR = texcoord;
	//IPD Right Adjustment
	TCL.x -= Interpupillary_Distance*0.5f;
	TCR.x += Interpupillary_Distance*0.5f;

	float D = Divergence;

	float FadeIO = smoothstep(0,1,1-Fade_in_out(texcoord).x), FD = D, FD_Adjust = 0.1;

	if( Eye_Fade_Reduction_n_Power.y == 1)
		FD_Adjust = 0.2;
	else if( Eye_Fade_Reduction_n_Power.y == 2)
		FD_Adjust = 0.3;

	if (FPSDFIO == 1 || FPSDFIO == 2)
		FD = lerp(FD * FD_Adjust,FD,FadeIO);

	float2 DLR = float2(FD,FD);
	if( Eye_Fade_Reduction_n_Power.x == 1)
			DLR = float2(D,FD);
	else if( Eye_Fade_Reduction_n_Power.x == 2)
			DLR = float2(FD,D);
//Left & Right Parallax for Stereo Vision
#if HUD_MODE || HM
	float HUD_Adjustment = ((0.5 - HUD_Adjust.y)*25.) * pix.x;
#endif

#if HelixVision
	float4 L = saturation( float4(MouseCursor( Parallax(-DLR.x, float2(TCL.x * 2,TCL.y))).rgb,1.0) ),
		   R = saturation( float4(MouseCursor( Parallax( DLR.y, float2(TCR.x  * 2 - 1,TCR.y))).rgb,1.0) );
	#if HUD_MODE || HM
		L.rgb = HUD(L.rgb,float2((TCL.x * 2) - HUD_Adjustment,TCL.y));
		R.rgb = HUD(R.rgb,float2((TCR.x  * 2 - 1) + HUD_Adjustment,TCR.y));
	#endif
	Double = StoreTC.x < 0.5 ? L : R; //Stereoscopic 3D using Reprojection Left & Right
#else
	Left =  saturation(float4(MouseCursor( Parallax(-DLR.x, TCL)).rgb,1.0)) ; //Stereoscopic 3D using Reprojection Left
	Right = saturation(float4(MouseCursor( Parallax( DLR.y, TCR)).rgb,1.0)) ;//Stereoscopic 3D using Reprojection Right
	#if HUD_MODE || HM
		Left.rgb = HUD(Left.rgb,float2(TCL.x - HUD_Adjustment,TCL.y));
		Right.rgb = HUD(Right.rgb,float2(TCR.x + HUD_Adjustment,TCR.y));
	#endif
#endif
}
///////////////////////////////////////////////////////////Barrel Distortion///////////////////////////////////////////////////////////////////////
float4 Circle(float4 C, float2 TC)
{
	if(Barrel_Distortion == 2)
		discard;

	float2 C_A = float2(1.0f,1.1375f), midHV = (C_A-1) * float2(BUFFER_WIDTH * 0.5,BUFFER_HEIGHT * 0.5) * pix;

	float2 uv = float2(TC.x,TC.y);

	uv = float2((TC.x*C_A.x)-midHV.x,(TC.y*C_A.y)-midHV.y);

	float borderA = 2.5; // 0.01
	float borderB = 0.003;//Vignette*0.1; // 0.01
	float circle_radius = 0.55; // 0.5
	float4 circle_color = 0; // vec4(1.0, 1.0, 1.0, 1.0)
	float2 circle_center = 0.5; // vec2(0.5, 0.5)
	// Offset uv with the center of the circle.
	uv -= circle_center;

	float dist =  sqrt(dot(uv, uv));

	float t = 1.0 + smoothstep(circle_radius, circle_radius+borderA, dist)
				  - smoothstep(circle_radius-borderB, circle_radius, dist);

	return lerp(circle_color, C,t);
}

float Vignette(float2 TC)
{   float CalculateV = lerp(1.0,0.25,smoothstep(0,1, Motion_Blinders(TC) ));
	float2 IOVig = float2(CalculateV * 0.75,CalculateV),center = float2(0.5,0.5); // Position for the innter and Outer vignette + Magic number scaling
	float distance = length(center-TC),Out = 0;
	// Generate the Vignette with Clamp which go from outer Viggnet ring to inner vignette ring with smooth steps
	if(Blinders > 0)
		Out = 1-saturate((IOVig.x-distance) / (IOVig.y-IOVig.x));
	return Out;
}
//SamplerDouble
float3 L(float2 texcoord)
{
	#if HelixVision
		float3 Left;
	#else
		float3 Left = tex2D(SamplerLeft,texcoord).rgb;
	#endif
	return lerp(Left,0,Vignette(texcoord));
}

float3 R(float2 texcoord)
{
	#if HelixVision
		float3 Right;
	#else
		float3 Right = tex2D(SamplerRight,texcoord).rgb;
	#endif
	return lerp(Right,0,Vignette(texcoord));
}

float2 BD(float2 p, float k1, float k2) //Polynomial Lens + Radial lens undistortion filtering Left & Right
{
	if(!Barrel_Distortion)
		discard;
	// Normalize the u,v coordinates in the range [-1;+1]
	p = (2.0f * p - 1.0f) / 1.0f;
	// Calculate Zoom
	if(!Theater_Mode)
		p *= 0.83;
	else
		p *= 0.8;
	// Calculate l2 norm
	float r2 = p.x*p.x + p.y*p.y;
	float r4 = pow(r2,2);
	// Forward transform
	float x2 = p.x * (1.0 + k1 * r2 + k2 * r4);
	float y2 = p.y * (1.0 + k1 * r2 + k2 * r4);
	// De-normalize to the original range
	p.x = (x2 + 1.0) * 1.0 / 2.0;
	p.y = (y2 + 1.0) * 1.0 / 2.0;

	if(!Theater_Mode)
	{
	//Blinders Code Fast
	float C_A1 = 0.45f, C_A2 = C_A1 * 0.5f, C_B1 = 0.375f, C_B2 = C_B1 * 0.5f, C_C1 = 0.9375f, C_C2 = C_C1 * 0.5f;//offsets
	if(length(p.xy*float2(C_A1,1.0f)-float2(C_A2,0.5f)) > 0.5f)
		p = 1000;//offscreen
	else if(length(p.xy*float2(1.0f,C_B1)-float2(0.5f,C_B2)) > 0.5f)
		p = 1000;//offscreen
	else if(length(p.xy*float2(C_C1,1.0f)-float2(C_C2,0.5f)) > 0.625f)
		p = 1000;//offscreen
	}

return p;
}
// For Super3D a new Stereo3D output Left and Right Image compression
float3 YCbCrLeft(float2 texcoord)
{
	return RGBtoYCbCr(L(texcoord));
}

float3 YCbCrRight(float2 texcoord)
{
	return RGBtoYCbCr(R(texcoord));
}
///////////////////////////////////////////////////////////Stereo Distortion Out///////////////////////////////////////////////////////////////////////
float3 PS_calcLR(float2 texcoord)
{
	float2 gridxy = floor(float2(texcoord.x * BUFFER_WIDTH, texcoord.y * BUFFER_HEIGHT)), TCL = float2(texcoord.x * 2,texcoord.y), TCR = float2(texcoord.x * 2 - 1,texcoord.y), uv_redL, uv_greenL, uv_blueL, uv_redR, uv_greenR, uv_blueR;
	float4 color, Left, Right, color_redL, color_greenL, color_blueL, color_redR, color_greenR, color_blueR;
	float K1_Red = Polynomial_Colors_K1.x, K1_Green = Polynomial_Colors_K1.y, K1_Blue = Polynomial_Colors_K1.z;
	float K2_Red = Polynomial_Colors_K2.x, K2_Green = Polynomial_Colors_K2.y, K2_Blue = Polynomial_Colors_K2.z;
	float Y_Left, Y_Right, CbCr_Left, CbCr_Right, CbCr;

	if(Barrel_Distortion == 0 || SuperDepth == 1)
	{   if(!SuperDepth)
		{   //Had to change float4 to float3.... Error only shows under linux.
			if(HelixVision)
			{
				Left.rgb = tex2D(BackBufferCLAMP,texcoord).rgb;
				//Right.rgb = R(float2(texcoord.x - 1,texcoord.y)).rgb;
			}
			else
			{
				Left.rgb = L(TCL).rgb;
				Right.rgb = R(TCR).rgb;
			}
		}
		else // For Super3D a new Stereo3D output.
		{
			Y_Left = YCbCrLeft(texcoord).x;
			Y_Right = YCbCrRight(texcoord).x;

			CbCr_Left = texcoord.x < 0.5 ? YCbCrLeft(texcoord * 2).y : YCbCrLeft(texcoord * 2 - float2(1,0)).z;
			CbCr_Right = texcoord.x < 0.5 ? YCbCrRight(texcoord * 2 - float2(0,1)).y : YCbCrRight(texcoord * 2 - 1 ).z;

			CbCr = texcoord.y < 0.5 ? CbCr_Left : CbCr_Right;
		}
	}
	else
	{
		uv_redL = BD(TCL.xy,K1_Red,K2_Red);
		uv_greenL = BD(TCL.xy,K1_Green,K2_Green);
		uv_blueL = BD(TCL.xy,K1_Blue,K2_Blue);

		color_redL = L(uv_redL).r;
		color_greenL = L(uv_greenL).g;
		color_blueL = L(uv_blueL).b;

		Left = float4(color_redL.x, color_greenL.y, color_blueL.z, 1.0);

		uv_redR = BD(TCR.xy,K1_Red,K2_Red);
		uv_greenR = BD(TCR.xy,K1_Green,K2_Green);
		uv_blueR = BD(TCR.xy,K1_Blue,K2_Blue);

		color_redR = R(uv_redR).r;
		color_greenR = R(uv_greenR).g;
		color_blueR = R(uv_blueR).b;

		Right = float4(color_redR.x, color_greenR.y, color_blueR.z, 1.0);
	}

	if(!overlay_open || NCAOC)
	{
		if(!SuperDepth)
		{
			if(Barrel_Distortion == 1) // Side by Side for VR
				color = texcoord.x < 0.5 ? Circle(Left,float2(texcoord.x*2,texcoord.y)) : Circle(Right,float2(texcoord.x*2-1,texcoord.y));
			else//Helix Vison Mode
				color =  HelixVision ? Left : texcoord.x < 0.5 ? Left : Right;
		}
		else
		{	// Super3D Mode
			color.rgb = float3(Y_Left,Y_Right,CbCr);
		}
	}
	else
	{
			color.rgb = HelixVision ? Left.rgb : fmod(gridxy.x+gridxy.y,2) ? R(texcoord) : L(texcoord);
	}

	if (BD_Options == 2 || Alinement_View)
		color.rgb = dot(0.5-tex2D(BackBuffer,texcoord).rgb,0.333) / float3(1,tex2D(SamplerzBufferVR,texcoord).x,1);

	return color.rgb;
}
/////////////////////////////////////////////////////////Average Luminance Textures/////////////////////////////////////////////////////////////////
float Past_BufferVR(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(SamplerDMVR,texcoord).w;
}

void Average_Luminance(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float3 AL : SV_Target0, out float2 Other : SV_Target1)
{
	float4 ABEA, ABEArray[6] = {
		float4(0.0,1.0,0.0, 1.0),           //No Edit
		float4(0.0,1.0,0.0, 0.750),         //Upper Extra Wide
		float4(0.0,1.0,0.0, 0.5),           //Upper Wide
		float4(0.0,1.0, 0.15625, 0.46875),  //Upper Short
		float4(0.375, 0.250, 0.4375, 0.125),//Center Small
		float4(0.375, 0.250, 0.0, 1.0)      //Center Long
	};
	ABEA = ABEArray[Auto_Balance_Ex];

	float Average_Lum_ZPD = PrepDepth(float2(ABEA.x + texcoord.x * ABEA.y, ABEA.z + texcoord.y * ABEA.w))[0][0], Average_Lum_Bottom = PrepDepth( texcoord )[0][0];
	if(RE)
	Average_Lum_Bottom = tex2D(SamplerDMVR,float2( 0.125 + texcoord.x * 0.750,0.95 + texcoord.y)).x;
	// SamplerDMVR 0 is Weapon State storage and SamplerDMVR 1 is Boundy State storage
	float Storage_One = texcoord.x < 0.5 ?  tex2D(SamplerDMVR,0).x : tex2D(SamplerDMVR,1).x;
	float Storage_Two = texcoord.x < 0.5 ?  tex2D(SamplerDMVR,float2(0,1)).x : 0;
	AL = float3(Average_Lum_ZPD,Average_Lum_Bottom,Storage_One);
	Other = float2(length(tex2D(SamplerDMVR,texcoord).w - tex2D(SamplerPBBVR,texcoord).x),Storage_Two);//Motion_Detection
}
////////////////////////////////////////////////////////////////////Logo////////////////////////////////////////////////////////////////////////////
#define _f float // Text rendering code copied/pasted from https://www.shadertoy.com/view/4dtGD2 by Hamneggs
static const _f CH_A    = _f(0x69f99), CH_B    = _f(0x79797), CH_C    = _f(0xe111e),
				CH_D    = _f(0x79997), CH_E    = _f(0xf171f), CH_F    = _f(0xf1711),
				CH_G    = _f(0xe1d96), CH_H    = _f(0x99f99), CH_I    = _f(0xf444f),
				CH_J    = _f(0x88996), CH_K    = _f(0x95159), CH_L    = _f(0x1111f),
				CH_M    = _f(0x9fd99), CH_N    = _f(0x9bd99), CH_O    = _f(0x69996),
				CH_P    = _f(0x79971), CH_Q    = _f(0x69b5a), CH_R    = _f(0x79759),
				CH_S    = _f(0xe1687), CH_T    = _f(0xf4444), CH_U    = _f(0x99996),
				CH_V    = _f(0x999a4), CH_W    = _f(0x999f9), CH_X    = _f(0x99699),
				CH_Y    = _f(0x99e8e), CH_Z    = _f(0xf843f), CH_0    = _f(0x6bd96),
				CH_1    = _f(0x46444), CH_2    = _f(0x6942f), CH_3    = _f(0x69496),
				CH_4    = _f(0x99f88), CH_5    = _f(0xf1687), CH_6    = _f(0x61796),
				CH_7    = _f(0xf8421), CH_8    = _f(0x69696), CH_9    = _f(0x69e84),
				CH_APST = _f(0x66400), CH_PI   = _f(0x0faa9), CH_UNDS = _f(0x0000f),
				CH_HYPH = _f(0x00600), CH_TILD = _f(0x0a500), CH_PLUS = _f(0x02720),
				CH_EQUL = _f(0x0f0f0), CH_SLSH = _f(0x08421), CH_EXCL = _f(0x33303),
				CH_QUES = _f(0x69404), CH_COMM = _f(0x00032), CH_FSTP = _f(0x00002),
				CH_QUOT = _f(0x55000), CH_BLNK = _f(0x00000), CH_COLN = _f(0x00202),
				CH_LPAR = _f(0x42224), CH_RPAR = _f(0x24442);
#define MAP_SIZE float2(4,5)
#undef flt
//returns the status of a bit in a bitmap. This is done value-wise, so the exact representation of the float doesn't really matter.
float getBit( float map, float index )
{   // Ooh -index takes out that divide :)
    return fmod( floor( map * exp2(-index) ), 2.0 );
}

float drawChar( float Char, float2 pos, float2 size, float2 TC )
{   // Subtract our position from the current TC so that we can know if we're inside the bounding box or not.
    TC -= pos;
    // Divide the screen space by the size, so our bounding box is 1x1.
    TC /= size;
    // Create a place to store the result & Branchless bounding box check.
    float res = step(0.0,min(TC.x,TC.y)) - step(1.0,max(TC.x,TC.y));
    // Go ahead and multiply the TC by the bitmap size so we can work in bitmap space coordinates.
    TC *= MAP_SIZE;
    // Get the appropriate bit and return it.
    res*=getBit( Char, 4.0*floor(TC.y) + floor(TC.x) );
    return saturate(res);
}

float3 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 TC = float2(texcoord.x,1-texcoord.y);
	float Menu_Open = overlay_open ? 1 : 0 , Text_Timer = 25000, BT = smoothstep(0,1,sin(timer*(3.75/1000))), Size = 1.1, Depth3D, Read_Help, Supported, SetFoV, FoV, Post, Effect, NoPro, NotCom, Mod, Needs, Net, Over, Set, AA, Emu, Not, No, Help, Fix, Need, State, SetAA, SetWP, Work;
	float3 Color = PS_calcLR(texcoord).rgb, SBS_3D = float3(1,0,0), Super3D = float3(0,0,1);
	//RGBW / R = SBS-3D / G = ?????? / B = Super3D / W = ??????
	float3 Format = !SuperDepth ? SBS_3D : Super3D;
	//Ok so I have to invert the pattern because for some reason the unity app I made can only read Integers values from ReShade.....
	float2 ScreenPos = float2(1-texcoord.x,1-texcoord.y) * Res;//This Bugg was waisted a entire day. But, this is the workaround for that.
	float Debug_Y = 1.0;// Set this higher so you can see it when Debugging
	if(all(abs(float2(1.0,BUFFER_HEIGHT)-ScreenPos.xy) < float2(1.0,Debug_Y)))
		Color = Menu_Open ? Format : 0;
	if(all(abs(float2(3.0,BUFFER_HEIGHT)-ScreenPos.xy) < float2(1.0,Debug_Y)))
		Color = Menu_Open ? 0 : Format;
	if(all(abs(float2(5.0,BUFFER_HEIGHT)-ScreenPos.xy) < float2(1.0,Debug_Y)))
		Color = Menu_Open ? Format : 0;
	//Now off to Unity to write the capturing of this information.
	if(RH || NC || NP || NF || PE || DS || OS || DA || NW || WW || FV || ED)
		Text_Timer = 30000;

	[branch] if(timer <= Text_Timer || Text_Info)
	{ // Set a general character size...
		float2 charSize = float2(.00875, .0125) * Size;
		// Starting position.
		float2 charPos = float2( 0.009, 0.9725);
		//Needs Copy Depth and/or Depth Selection
		Needs += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_C, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_Y, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_H, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_H, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_C, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Needs += drawChar( CH_N, charPos, charSize, TC);
		//Network Play May Need Modded DLL
		charPos = float2( 0.009, 0.955);
		Work += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_W, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_K, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_Y, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_M, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_Y, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_M, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		Work += drawChar( CH_L, charPos, charSize, TC);
		//Supported Emulator Detected
		charPos = float2( 0.009, 0.9375);
		Supported += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_U, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_M, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_U, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_C, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Supported += drawChar( CH_D, charPos, charSize, TC);
		//Disable CA/MB/Dof/Grain
		charPos = float2( 0.009, 0.920);
		Effect += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_B, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_C, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_M, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_B, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_F, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_G, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		Effect += drawChar( CH_N, charPos, charSize, TC);
		//Disable Or Set TAA/MSAA/AA/DLSS
		charPos = float2( 0.009, 0.9025);
		SetAA += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_B, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_M, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		SetAA += drawChar( CH_S, charPos, charSize, TC);
		//Set Weapon Profile
		charPos = float2( 0.009, 0.885);
		SetWP += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_W, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_F, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		SetWP += drawChar( CH_E, charPos, charSize, TC);
		//Set FoV
		charPos = float2( 0.009, 0.8675);
		SetFoV += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		SetFoV += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		SetFoV += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		SetFoV += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		SetFoV += drawChar( CH_F, charPos, charSize, TC); charPos.x += .01 * Size;
		SetFoV += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		SetFoV += drawChar( CH_V, charPos, charSize, TC);
		//Read Help
		charPos = float2( 0.894, 0.9725);
		Read_Help += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_H, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		Read_Help += drawChar( CH_P, charPos, charSize, TC);
		//New Start
		charPos = float2( 0.009, 0.018);
		// No Profile
		NoPro += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_F, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		NoPro += drawChar( CH_E, charPos, charSize, TC); charPos.x = 0.009;
		//Not Compatible
		NotCom += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_C, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_P, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_B, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_L, charPos, charSize, TC); charPos.x += .01 * Size;
		NotCom += drawChar( CH_E, charPos, charSize, TC); charPos.x = 0.009;
		//Needs Fix/Mod
		Mod += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_D, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_F, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_X, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_SLSH, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_M, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		Mod += drawChar( CH_D, charPos, charSize, TC); charPos.x = 0.009;
		//Overwatch.fxh Missing
		State += drawChar( CH_O, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_V, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_E, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_R, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_W, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_A, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_T, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_C, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_H, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_FSTP, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_F, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_X, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_H, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_BLNK, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_M, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_S, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_I, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_N, charPos, charSize, TC); charPos.x += .01 * Size;
		State += drawChar( CH_G, charPos, charSize, TC);
		//New Size
		float D3D_Size_A = 1.375,D3D_Size_B = 0.75;
		float2 charSize_A = float2(.00875, .0125) * D3D_Size_A, charSize_B = float2(.00875, .0125) * D3D_Size_B;
		//New Start Pos
		charPos = float2( 0.862, 0.018);
		//Depth3D.Info Logo/Website
		Depth3D += drawChar( CH_D, charPos, charSize_A, TC); charPos.x += .01 * D3D_Size_A;
		Depth3D += drawChar( CH_E, charPos, charSize_A, TC); charPos.x += .01 * D3D_Size_A;
		Depth3D += drawChar( CH_P, charPos, charSize_A, TC); charPos.x += .01 * D3D_Size_A;
		Depth3D += drawChar( CH_T, charPos, charSize_A, TC); charPos.x += .01 * D3D_Size_A;
		Depth3D += drawChar( CH_H, charPos, charSize_A, TC); charPos.x += .01 * D3D_Size_A;
		Depth3D += drawChar( CH_3, charPos, charSize_A, TC); charPos.x += .01 * D3D_Size_A;
		Depth3D += drawChar( CH_D, charPos, charSize_A, TC); charPos.x += 0.008 * D3D_Size_A;
		Depth3D += drawChar( CH_FSTP, charPos, charSize_A, TC); charPos.x += 0.01 * D3D_Size_A;
		charPos = float2( 0.963, 0.018);
		Depth3D += drawChar( CH_I, charPos, charSize_B, TC); charPos.x += .01 * D3D_Size_B;
		Depth3D += drawChar( CH_N, charPos, charSize_B, TC); charPos.x += .01 * D3D_Size_B;
		Depth3D += drawChar( CH_F, charPos, charSize_B, TC); charPos.x += .01 * D3D_Size_B;
		Depth3D += drawChar( CH_O, charPos, charSize_B, TC);
		//Text Information
		if(DS)
			Need = Needs;
		if(RH)
			Help = Read_Help;
		if(NW)
			Net = Work;
		if(PE)
			Post = Effect;
		if(WW)
			Set = SetWP;
		if(DA)
			AA = SetAA;
		if(FV)
			FoV = SetFoV;
		if(ED)
			Emu = Supported;
		//Blinking Text Warnings
		if(NP)
			No = NoPro * BT;
		if(NC)
			Not = NotCom * BT;
		if(NF)
			Fix = Mod * BT;
		if(OS)
			Over = State * BT;
		//Website
		float3 WebInfo = Depth3D+Help+Post+No+Not+Net+Fix+Need+Over+AA+Set+FoV+Emu;
		return (SuperDepth ? float3(WebInfo.rg,0) : WebInfo) ? (1-texcoord.y*50.0+48.85)*texcoord.y-0.500 : Color;
	}
	else
		return Color;
}
///////////////////////////////////////////////////////////////////SmartSharp Jr.//////////////////////////////////////////////////////////////////////
#define SIGMA 0.25
#define MSIZE 3

float normpdf3(in float3 v, in float sigma)
{
	return 0.39894*exp(-0.5*dot(v,v)/(sigma*sigma))/sigma;
}

float LI(float3 RGB)
{
	return dot(RGB,float3(0.2126, 0.7152, 0.0722));
}

float3 SmartSharp(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{   float Sharp_This = overlay_open ? 0 : Sharpen_Power,mx, mn;
	float2 tex_offset = pix; // Gets texel offset
	float3 c = tex2D(BackBuffer, texcoord).rgb;
	if(Sharp_This > 0)
	{
		//Bilateral Filter//                                                Q1         Q2       Q3        Q4
	const int kSize = MSIZE * 0.5; // Default M-size is Quality 2 so [MSIZE 3] [MSIZE 5] [MSIZE 7] [MSIZE 9] / 2.

	float3 final_color, cc;
	float2 RPC_WS = pix * 1.5;
	float Z, factor;

	[loop]
	for (int i=-kSize; i <= kSize; ++i)
	{
		for (int j=-kSize; j <= kSize; ++j)
		{
			cc = tex2Dlod(BackBuffer, float4(texcoord.xy + float2(i,j) * RPC_WS * rcp(kSize * 2.0f),0,0)).rgb;
			factor = normpdf3(cc-c, SIGMA);
			Z += factor;
			final_color += factor * cc;
		}
	}

	final_color = saturate(final_color/Z);

	mn = min( min( LI(c), LI(final_color)), LI(cc));
	mx = max( max( LI(c), LI(final_color)), LI(cc));

   // Smooth minimum distance to signal limit divided by smooth max.
    float rcpM = rcp(mx), CAS_Mask;// = saturate(min(mn, 1.0 - mx) * rcpM);

	// Shaping amount of sharpening masked
	CAS_Mask = saturate(min(mn, 2.0 - mx) * rcpM);

	float3 Sharp_Out = c + (c - final_color) * Sharp_This;
	//Consideration for Super3D mode
	c = SuperDepth ? lerp(c,float3(Sharp_Out.rg,c.b),CAS_Mask) : lerp(c,Sharp_Out,CAS_Mask);
	}

	return c;
}
///////////////////////////////////////////////////////////////////ReShade.fxh//////////////////////////////////////////////////////////////////////
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{// Vertex shader generating a triangle covering the entire screen
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
technique SuperDepth3D_VR
< ui_tooltip = "Suggestion : Please enable 'Performance Mode Checkbox,' in the lower bottom right of the ReShade's Main UI.\n"
			   "             Do this once you set your 3D settings of course."; >
{
	#if D_Frame || DF
		pass Delay_Frame
	{
		VertexShader = PostProcessVS;
		PixelShader = DelayFrame;
		RenderTarget = texDF;
	}
		pass Current_Frame
	{
		VertexShader = PostProcessVS;
		PixelShader = CurrentFrame;
		RenderTarget = texCF;
	}
	#endif
		pass DepthBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = DepthMap;
		RenderTarget0 = texDMVR;
	}
		pass zbufferVR
	{
		VertexShader = PostProcessVS;
		PixelShader = zBuffer;
		RenderTarget = texzBufferVR;
	}
		pass StereoBuffers
	{
		VertexShader = PostProcessVS;
		PixelShader = LR_Out;
		#if HelixVision
		RenderTarget0 = DoubleTex;//Can run into DX9 size Limitations
		#else
		RenderTarget0 = LeftTex;
		RenderTarget1 = RightTex;
		#endif
	}
		pass StereoOut
	{
		VertexShader = PostProcessVS;
		PixelShader = Out;
	}
	#if !HelixVision //Removed because HelixVision_Mode Has Built in sharpening.
		pass USMOut
	{
		VertexShader = PostProcessVS;
		PixelShader = SmartSharp;
	}
	#endif
		pass AverageLuminance
	{
		VertexShader = PostProcessVS;
		PixelShader = Average_Luminance;
		RenderTarget0 = texLumVR;
		RenderTarget1 = texOtherVR;
	}
		pass PastBBVR
	{
		VertexShader = PostProcessVS;
		PixelShader = Past_BufferVR;
		RenderTarget = texPBVR;
	}
}
