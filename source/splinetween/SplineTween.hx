package splinetween;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
#if flixel_addons
import flixel.addons.effects.FlxSkewedSprite;
#end
import flixel.FlxSprite;

class SplineTween implements IFlxDestroyable {
	/**
	 * The tween manager that the tweens use if tweens are enabled
	 */
	public static var tweenManager:FlxTweenManager = null;
	/**
	 * The timer manager that timers will use if tweens are disabled
	 */
	public static var timerManager:FlxTimerManager = null;

	var fps = 1/24;
	var generatedPoints:Array<SplinePoint> = [];
	var obj:FlxSprite;
	#if flixel_addons
	var skewobj:FlxSkewedSprite;
	#end
	var frame = 0;
	var tweened = true;
	var onComplete:SplineTween->Void;
	/**
	 * Create's a spline tween.
	 * @param obj The sprite to tween
	 * @param points An array of SplinePoints
	 * @param options Optional options to option the option
	 */
	public function new(obj:FlxSprite, points:Array<SplinePoint>, ?options:SplineOptions) {
		//super();
		this.obj = obj;
		#if flixel_addons
		if(obj is FlxSkewedSprite) {
			skewobj = cast obj;
		}
		#end
		if(options != null) {
			if(options.fps != null) fps = options.fps;
			if(options.tweened != null) tweened = options.tweened;
			onComplete = options.onComplete;
		}
		var elapsed = .0;
		//maxt = points[points.length-1].time;
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
			while(fi < fi2.time) { //looks stupid i was just trying to replicate the original jsfl whateverrrr
				frame = fi;
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
		if(tweened) currentTween.cancel();
		else currentTimer.cancel();
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
		trace('the final one is ${generatedPoints[generatedPoints.length - 1]}');
		if(destroy) this.destroy();
	}
	/**
	 * Begins the spline tween
	 */
	public function start() {
		tweenLoop();
		started = true;
		return this;
	}
	
	/**
	 * Whether the tween is paused or not
	 */
	public var paused(default, set):Bool;
	function set_paused(v:Bool) {
		if(tweened) {
			currentTween.active = !v;
		}else{
			currentTimer.active = !v;
		}
		return paused = v;
	}
	var tweenIndex = 0;
	var currentTween:FlxTween;
	var currentTimer:FlxTimer;
	function tweenLoop(?_:OneOfTwo<FlxTween, FlxTimer>) {
		//trace('hi');
		var p = generatedPoints[tweenIndex];
		var prevp = generatedPoints[tweenIndex - 1];
		if(prevp != null){
			prevp.position.put();
			prevp.scale.put();
			#if flixel_addons
			prevp.skew.put();
			#end
		}
		if(p != null) {
			//trace('im gonna do this now');
			tweened ? {
				if(currentTween != null) currentTween.destroy();
				currentTween = FlxTween.tween(obj, #if flixel_addons (skewobj != null) ? {
					x: p.position.x,
					y: p.position.y,
					'scale.x': p.scale.x,
					'scale.y': p.scale.y,
					'skew.x': p.skew.x,
					'skew.y': p.skew.y,
					angle: p.angle,
				} : #end {
					x: p.position.x,
					y: p.position.y,
					'scale.x': p.scale.x,
					'scale.y': p.scale.y,
					angle: p.angle,
				}, fps, {onComplete: tweenLoop});
			} : {
				applyPoint(p);
				currentTimer = new FlxTimer().start(fps, tweenLoop);
			}
			tweenIndex++;
		}else{
			finish();
			if(onComplete != null) {
				onComplete(this);
			}
		}
	}
	var pointBuffer:SplinePoint;
	function interpolateElement(t:Float, el0:SplinePoint, el1:SplinePoint, el2:SplinePoint, el3:SplinePoint) {
		pointBuffer = new SplinePoint(frame);
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
		generatedPoints[frame - 1] = pointBuffer;
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
	public function destroy() {
		generatedPoints = null;
		obj = null;
		#if flixel_addons
		skewobj = null;
		#end
		onComplete = null;
	}
	function applyPoint(p:SplinePoint) {
		obj.setPosition(p.position.x, p.position.y);
		obj.scale.copyFrom(p.scale);
		obj.updateHitbox();
		obj.angle = p.angle;
		#if flixel_addons
		if(skewobj != null) skewobj.skew.copyFrom(p.skew);
		#end
		if(currentTimer != null) currentTimer.destroy();
	}
}
typedef SplineOptions = {
	?fps:Null<Float>,
	?tweened:Null<Bool>,
	?onComplete:SplineTween->Void,
}
enum SplinePropType {
	POS(axes:FlxAxes);
	SCALE(axes:FlxAxes);
	ANGLE;
	#if flixel_addons
	SKEW(axes:FlxAxes);
	#end
}