package splinetween;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.FlxBasic;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
#if flixel_addons
import flixel.addons.effects.FlxSkewedSprite;
#end
import flixel.FlxSprite;

class SplineTween extends FlxBasic implements IFlxDestroyable {
	public static var globalManager:SplineTweenManager;
	/**
	 * The tweens local manager usually is global manager
	 */
	public var manager:SplineTweenManager;
	var fps = 24.0;
	var generatedPoints:Array<SplinePoint> = [];
	var obj:FlxSprite;
	#if flixel_addons
	var skewobj:FlxSkewedSprite;
	#end

	/**
	 * The current frame
	 */
	public var frame = 0;
	/**
	 * Unfloored frame
	 */
	public var frameTime = 0.0;

	var _frameBuffer = 0;
	var tweened = true;
	var onComplete:SplineTween->Void;
	/**
	 * The amount of loops left, will be ignored of number of loops isnt set from tween function!
	 */
	public var loops = -1;
	var _doLoop = false;
	var _infiniteLoop = true;
	var _loopPoint = 0;

	/**
	 * Whether to automatically desotroy the tween when finished
	 */
	public var autoDestroy = true;
	/**
	 * Create's a spline tween.
	 * @param obj The sprite to tween
	 * @param points An array of SplinePoints
	 * @param options Optional options to option the option
	 */
	public static function tween(obj:FlxSprite, points:SplinePointList, ?options:SplineOptions):SplineTween {
		if(!_inited) _init();
		return globalManager.tween(obj, points, options);
	}
	public function new(obj:FlxSprite, points:SplinePointList, ?options:SplineOptions) {
		super();
		this.obj = obj;
		#if flixel_addons
		if(obj is FlxSkewedSprite) {
			skewobj = cast obj;
		}
		#end
		var loopLength = -1;
		if(options != null) {
			if(options.fps != null) fps = options.fps;
			if(options.tweened != null) tweened = options.tweened;
			if(options.loops != null) loops = options.loops;
			if(options.loopLength != null) loopLength = options.loopLength;
			_doLoop = loops >= 0;
			_infiniteLoop = loops == 0;
			onComplete = options.onComplete;
		}
		var elapsed = .0;
		//maxt = points[points.length-1].time;
		var points:Array<SplinePoint> = [for(p in points) {
			if(p is Array) SplinePoint.fromArray(cast p);
			else cast p;
		}];
		if(_doLoop) {
			for(i in 0...3) {
				//trace('adding ${points[i]} to the end of my thing');
				points.push(points[i].copy(points[points.length - 1].time + points[i].time + loopLength));
			}
		}
		if(points[0].time > 1) points.insert(0, points[0].copy(1));
		for(i in 0...points.length) {
			var fi0 = points[Std.int(Math.max(0, i - 1))];
			var fi1 = points[i + 0]; //?????????????????????
			if(fi1.time <= 0) throw 'frame cant be 0 lool';
			var fi2 = points[Std.int(Math.min(i + 1, points.length - 1))];
			var fi3 = points[Std.int(Math.min(i + 2, points.length - 1))];
			generatedPoints[fi1.time-1] = fi1;
			//trace('i am ${fi1.time} and i put myself $fi1 there');
			if(generatedPoints[fi0.time] == null) generatedPoints[fi0.time] = fi0;
			var fi = fi1.time;
			if(i == points.length - 3) {
				_loopPoint = generatedPoints.length - 1;
			}
			while(fi < fi2.time) { //looks stupid i was just trying to replicate the original jsfl whateverrrr
				_frameBuffer = fi;
				var t = (fi - fi1.time)/(fi2.time - fi1.time);
				//trace('i am $t');
				interpolateElement(t, fi0, fi1, fi2, fi3);
				fi++;
			}
		}
		generatedPoints.push(points[points.length - 1]);
	}
	/**
	 * Set to true when the tween starts
	 */
	public var started = false;
	/**
	 * set to true when the tween ends
	 */
	public var finished = false;
	/**
	 * Cancels the spline tween exactly where the objects at
	 * @param destroy = true Whether to destroy the tween
	 */
	public function cancel(?destroy = true) {
		if(!started || finished) return;
		active = false;
		if(destroy) this.destroy();
	}
	/**
	 * Finishes the spline tween by setting the object to the final point
	 * @param destroy = true Whether to destroy the tween or not
	 */
	public function finish(?destroy = true) {
		cancel(false);
		finished = true;
		applyPoint(generatedPoints[generatedPoints.length - 1]);
		//trace('the final one is ${generatedPoints[generatedPoints.length - 1]}');
		if(destroy) this.destroy();
	}
	/**
	 * Begins the spline tween
	 */
	public function start() {
		started = true;
		return this;
	}
	
	var pointBuffer:SplinePoint;
	function interpolateElement(t:Float, el0:SplinePoint, el1:SplinePoint, el2:SplinePoint, el3:SplinePoint) {
		pointBuffer = new SplinePoint(_frameBuffer);
		interpolateProperty(t, el0, el1, el2, el3, SCALE(X));
		interpolateProperty(t, el0, el1, el2, el3, SCALE(Y));
		interpolateProperty(t, el0, el1, el2, el3, POS(X));
		interpolateProperty(t, el0, el1, el2, el3, POS(Y));
		#if flixel_addons
		if(skewobj != null){
			interpolateProperty(t, el0, el1, el2, el3, SKEW(X));
			interpolateProperty(t, el0, el1, el2, el3, SKEW(Y));
		}
		#end
		interpolateProperty(t, el0, el1, el2, el3, ANGLE);
		generatedPoints[_frameBuffer - 1] = pointBuffer;
	}
	function interpolateProperty(t:Float, el0:SplinePoint, el1:SplinePoint, el2:SplinePoint, el3:SplinePoint, type:SplinePropType) {
		pointBuffer.setProperty(spline(t,
			el0.getProperty(type), el1.getProperty(type), el2.getProperty(type), el3.getProperty(type),
			el0, el1, el3), type);
	}
	function spline(t:Float, p0:Float, p1:Float, p2:Float, p3:Float, ?p0f:SplinePoint, ?p1f:SplinePoint, ?p2f:SplinePoint, ?p3f:SplinePoint) {
		//var t = time/maxt;
		if (p2f != null && p3f != null) {
			// calculate interval lengths
			var t12 = p2f.time - p1f.time;
			var cool = !(p1f == null || p0f == null);
			var t01 = cool ? (p1f.time - p0f.time) : t12;
			var t23 = cool ? (p3f.time - p2f.time) : t12;
	
			// multiply values accordingly,
			// so if the preceding interval is really short,
			// its value gets intensified to reflect that fast speed
			var mult01 = t12 / t01;
			var mult23 = t12 / t23;
			p0 = (p0 - p1) * mult01 + p1;
			p3 = (p3 - p2) * mult23 + p3;
		}
		return .5 * (
			2*p1 +
			(p2 - p0) * t +
			(2*p0 - 5*p1 + 4*p2 - p3) * t * t +
			(3*p1 - p0 - 3*p2 + p3) * t * t * t
		);
	}
	override function destroy() {
		super.destroy();
		for(p in generatedPoints) {
			if(!p.destroyed) p.destroy();
		}
		obj = null;
		#if flixel_addons
		skewobj = null;
		#end
		onComplete = null;
		manager.tweens.remove(this);
	}
	function applyPoint(p:SplinePoint) {
		obj.setPosition(p.position.x, p.position.y);
		obj.scale.copyFrom(p.scale);
		obj.updateHitbox();
		obj.angle = p.angle;
		#if flixel_addons
		if(skewobj != null) skewobj.skew.copyFrom(p.skew);
		#end
	}
	override function update(e:Float) {
		super.update(e);
		frameTime += e * fps;
		frame = Math.floor(frameTime);
		var p0 = generatedPoints[frame];
		var p1 = generatedPoints[frame + 1];
		if((_doLoop && loops > 0 || _infiniteLoop) && frame == _loopPoint) {
			frameTime = 0;
			loops--;
			if(!_infiniteLoop && loops <= 0) {
				finish(autoDestroy);
				return;
			}
		}
		if(p1 == null) {
			finish(autoDestroy);
			return;
		}
		if(tweened) {
			var lerp = frameTime % 1;
			lerpProp(lerp, p0, p1, SCALE(X));
			lerpProp(lerp, p0, p1, SCALE(Y));
			lerpProp(lerp, p0, p1, POS(X));
			lerpProp(lerp, p0, p1, POS(Y));
			lerpProp(lerp, p0, p1, ANGLE);
			#if flixel_addons
			if(skewobj != null){
				lerpProp(lerp, p0, p1, SKEW(X));
				lerpProp(lerp, p0, p1, SKEW(Y));
			}
			#end
		}else{
			applyPoint(p0);
		}
	}
	function lerpProp(lerp:Float, p0:SplinePoint, p1:SplinePoint, type:SplinePropType) {
		setProperty(FlxMath.lerp(p0.getProperty(type), p1.getProperty(type), lerp), type);
	}
	function getProperty(type:SplinePropType):Float {
		return switch type {
			case POS(axes): axes == X ? obj.x : obj.y;
			case SCALE(axes): axes == X ? obj.scale.x : obj.scale.y;
			#if flixel_addons
			case SKEW(axes): axes == X ? skewobj.skew.x : skewobj.skew.y;
			#end
			case ANGLE: obj.angle;
		}
	}
	function setProperty(v:Float, type:SplinePropType):Float {
		return switch type {
			case POS(axes): axes == X ? obj.x = v : obj.y = v;
			case SCALE(axes): axes == X ? obj.scale.x = v : obj.scale.y = v;
			#if flixel_addons
			case SKEW(axes): axes == X ? skewobj.skew.x = v : skewobj.skew.y = v;
			#end
			case ANGLE: obj.angle = v;
		}
	}

	static var _inited = false;
	static function _init() {
		_inited = true;
		globalManager = new SplineTweenManager();
		FlxG.plugins.add(globalManager);
	}
}
//semi based on FlxTweenManager
class SplineTweenManager extends FlxBasic {
	@:allow(splinetween.SplineTween) var tweens:Array<SplineTween> = [];
	public function new() {
		super();
		visible = false; //ok lol
		FlxG.signals.preStateSwitch.add(clear);
	}
	override function destroy() {
		super.destroy();
		FlxG.signals.preStateSwitch.remove(clear);
	}
	/**
	 * Clears it ALL IT  ALL GONE!!!!! AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH stolen lol
	 */
	public function clear() {
		for (tween in tweens)
		{
			if (tween != null)
			{
				tween.active = false;
				tween.destroy();
			}
		}
		tweens.splice(0, tweens.length);
	}
	public function tween(obj:FlxSprite, points:SplinePointList, ?options:SplineOptions):SplineTween {
		var twn = new SplineTween(obj, points, options);
		twn.manager = this;
		tweens.push(twn);
		return twn;
	}
	override function update(e:Float) {
		super.update(e);
		for(tween in tweens) {
			if(tween.active && !tween.finished && tween.started) {
				tween.update(e);
			}
		}
	}
}
typedef SplineOptions = {
	?fps:Null<Float>,
	?tweened:Null<Bool>,
	?onComplete:SplineTween->Void,
	?loops:Null<Int>,
	?loopLength:Null<Int>, //if the end point of the tween doesnt match the begining point, set this to something and frames from the end to start will be generated
}
typedef SplinePointList = Array<OneOfTwo<SplinePoint, Array<Float>>>;
enum SplinePropType {
	POS(axes:FlxAxes);
	SCALE(axes:FlxAxes);
	ANGLE;
	#if flixel_addons
	SKEW(axes:FlxAxes);
	#end
}