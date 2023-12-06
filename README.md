# splinetween
Haxeflixel library that adds a spline tween that is based off the spline tweens in bfb! credits to Micheal Huang for writing the original script i think

example:
```haxe
test = new FlxSkewedSprite();
test.makeGraphic(100, 200, FlxColor.GRAY);
add(test);
new SplineTween(test, [
	new SplinePoint(1, 500, 200, 1.2, 1.4, 32, 1.2, 1.5),
	new SplinePoint(6, 200, 100, 0.4, 0.6, -15, 2.3),
	new SplinePoint(14, 600, 100, 1.4, 1.6, 60, 1.5, 2.3),
	new SplinePoint(26, 500, 200, 1.2, 1.4, 32),
	new SplinePoint(50, 200, 100, 0.4, 0.6, -15, 1.2),
	new SplinePoint(82, 600, 100, 1.4, 1.6, 60, 50, 50),
	new SplinePoint(144),
]).start();
```
