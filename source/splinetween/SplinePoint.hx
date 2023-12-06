package splinetween;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxStringUtil;
import splinetween.SplineTween;
import flixel.math.FlxPoint;


@:allow(splinetween.SplineTween)
class SplinePoint implements IFlxDestroyable {
	var time:Int;
	var position = FlxPoint.get();
	var scale = FlxPoint.get();
	var angle = .0;
	#if flixel_addons
	var skew = FlxPoint.get();
	#end
	/**
	 * This is basically a 'keyframe'
	 * @param frame = -1 Frame that the point happens on **NOTE: THIS IS A MANUAL INDEX WHICH MEANS IT IS NOT X FRAMES AFTER BUT IS AT FRAME X**
	 * @param x = .0 
	 * @param y = .0 
	 * @param sx = 1. 
	 * @param sy = 1. 
	 * @param angle = .0 
	 * @param skewx = 1. 
	 * @param skewy = 1. 
	 */
	public function new(frame = -1, x = .0, y = .0, sx = 1., sy = 1., angle = .0 #if flixel_addons , ?skewx = .0, ?skewy = .0 #end) {
		position.set(x, y);
		scale.set(sx, sy);
		#if flixel_addons
		skew.set(skewx, skewy);
		#end
		this.angle = angle;
		time = frame;
	}
	function getProperty(type:SplinePropType):Float {
		return switch type {
			case POS(axes): axes == X ? position.x : position.y;
			case SCALE(axes): axes == X ? scale.x : scale.y;
			#if flixel_addons
			case SKEW(axes): axes == X ? skew.x : skew.y;
			#end
			case ANGLE: angle;
		}
	}
	function setProperty(v:Float, type:SplinePropType):Float {
		return switch type {
			case POS(axes): axes == X ? position.x = v : position.y = v;
			case SCALE(axes): axes == X ? scale.x = v : scale.y = v;
			#if flixel_addons
			case SKEW(axes): axes == X ? skew.x = v : skew.y = v;
			#end
			case ANGLE: angle = v;
		}
	}
	/**
	 * Copies the point
	 * @param time 
	 */
	public function copy(time) {
		return new SplinePoint(time, position.x, position.y, scale.x, scale.y, angle #if flixel_addons , skew.x, skew.y #end);
	}
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", position.x),
			LabelValuePair.weak("y", position.y),
			LabelValuePair.weak("scale x", scale.x),
			LabelValuePair.weak("scale y", scale.y),
			LabelValuePair.weak("angle", angle),
			LabelValuePair.weak("t", time),
		]);
	}
	public static function fromArray(a:Array<Float>) {
		var i = a.length;
		while(a.length < #if flixel_addons 7 #else 5 #end) {
			a.push((3 <= i && i <= 4) ? 1 : 0);
			i++;
		}
		return new SplinePoint(Std.int(a[0]), a[1], a[2], a[3], a[4], a[5] #if flixel_addons , a[6], a[7] #end);
	}

	var destroyed = false;
	public function destroy() {
		destroyed = true;
		position.put();
		scale.put();
		#if flixel_addons
		skew.put();
		#end
	}
}