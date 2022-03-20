package;

import flixel.tweens.FlxTween;
import flixel.addons.text.FlxTypeText;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.util.FlxTimer;
import Std;

class DialogueBox extends FlxSpriteGroup
{

var bgFade:FlxSprite;
var box:FlxSpriteGroup;
var currentSound:FlxSound = null;

var variables:Map<String,String> = [];
var graphics:Map<String,GraphicItem> = [];
var portraits:Map<String,Portrait> = [];
var dialogueText:Array<String> = [];
var textFileParser:Array<String> = [];

var currentState:PlayState;
var text:FlxTypeText;



    public function new(?filePath:String, state:PlayState)
    {
        super();
        if(filePath.toLowerCase() == null)
        {
            return;
        }    
        currentState = state;
        var textFileParser = CoolUtil.coolTextFile(filePath);
        var readingPortrait:Bool = false;
        var readingDialogue:Bool = false;
        var readingGraphic:Bool = false;
        //Reading Information
        for(i in 0...textFileParser.length)
        {
            trace(textFileParser[i]);

            switch(textFileParser[i].toLowerCase())
            {
                case 'graphics:':
                {
                    readingDialogue = false;
                    readingPortrait = false;
                    readingGraphic = true;
                }
                case 'portraits:':
                {
                    readingDialogue = false;
                    readingPortrait = true;
                    readingGraphic = false;
                    continue;
                }
                case 'dialogue:':
                {
                    readingDialogue = true;
                    readingPortrait = false;
                    readingGraphic = false;
                    continue;
                }
            }
            if(readingPortrait)
            {
                var temp1:Array<String> = textFileParser[i].split(":");
                var temp2:Array<String> = temp1[1].split(",");
                var portraitInfo:Array<String> = [null,null,null,null,null,null,null];
                for(i in 0...temp2.length)
                {
                    portraitInfo[i] = temp2[i];
                }
                portraits[temp1[0].toLowerCase()] = new Portrait(portraitInfo[0],portraitInfo[1],portraitInfo[2],
                    portraitInfo[3],portraitInfo[4],portraitInfo[5],portraitInfo[6]);
            }
            else if(readingDialogue)
            {
                dialogueText.push(textFileParser[i]);
            }
            else if(readingGraphic)
            {
                var temp1:Array<String> = textFileParser[i].split(":");
                var temp2:Array<String> = temp1[1].split(",");
                var graphicInfo:Array<String> = [null,null,null,null];
                for(i in 0...temp2.length)
                {
                    graphicInfo[i] = temp2[i];
                }
                graphics[temp1[0].toLowerCase()] = new GraphicItem(graphicInfo[0],graphicInfo[1],graphicInfo[2],
                    graphicInfo[3]);
            }
            else
            {
                var temp:Array<String> = textFileParser[i].split(":");
                variables[temp[0].toLowerCase()] = temp[1];
            }
        }
        
        //Using Information
        if(variables.exists("music"))
        {
            currentSound = FlxG.sound.play(Paths.music(variables.get("music")), 1,true);
            currentSound.fadeIn(1, 0, 0.8);
        }

		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer)
		{
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7)
				bgFade.alpha = 0.7;
		}, 5);

        new FlxTimer().start(1.2,function(tmr:FlxTimer)
        {
            text = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
            if(variables.exists("font"))
            {
                text.font = variables["font"];
            }
            else
            {
                text.font = 'Pixel Arial 11 Bold';
            }

            if(variables.exists("typeSound"))
            {
                text.sounds.push(new FlxSound().loadEmbedded(Paths.sound(variables.get("typeSound"))));
            }

            for(key=>value in graphics)
            {
                if(key == "box")
                {
                    box = dropDownAnimate(value.pathName,7,value.xOffset,value.yOffset,value.sizeFactor);
                    add(box);
                }
                else
                {
                    var item:FlxSprite = new FlxSprite(value.xOffset,value.yOffset).loadGraphic(Paths.image(value.pathName));
                    item.setGraphicSize(Std.int(value.sizeFactor*item.width));
                    item.updateHitbox();
                    add(item);
                }

            }
            add(currentPortraitSprite);
            changeDialogueAndPortrait();
            boxStart = true;
        },1);
    }
    var boxStart:Bool = false;
    var ending:Bool = false;

    var dialogueIndex:Int = 0;
    var curDialogue:String;
    var currentPortraitName:String;
    var currentPortraitSprite:FlxSprite;
    var portraitInfo:Portrait;
    
    override function update(elapsed:Float)
    {
        if(!boxStart || ending)
        {
            return;
        }
        if(PlayerSettings.player1.controls.ACCEPT)
        {
            if(dialogueIndex > dialogueText.length)
            {
                ending = true;
                if(currentSound != null)
                {
                    currentSound.fadeOut(2.2, 0, (tween -> [currentSound.destroy()]));
                }
                remove(currentPortraitSprite);
                new FlxTimer().start(0.2, function(tmr:FlxTimer)
				{
                    bgFade.alpha -= 1 / 5 * 0.7;
                    box.alpha -= 1 / 5;
                },5);
                new FlxTimer().start(1.2, function(tmr:FlxTimer)
                {
                    currentState.startCountdown();
                    currentState.remove(this);
                    destroy();
                },1);
            }
            else
            {
                changeDialogueAndPortrait();
            }
        }
        super.update(elapsed);
    }

    private function changeDialogueAndPortrait()
    {
        remove(currentPortraitSprite);
        currentPortraitName = dialogueText[dialogueIndex].split(":")[0];
        curDialogue = dialogueText[dialogueIndex].split(":")[1];
        text.text = curDialogue;
        text.start();
        portraitInfo = portraits[currentPortraitName];
        currentPortraitSprite = new FlxSprite(portraitInfo.xOffset,portraitInfo.yOffset).loadGraphic(portraitInfo.pathName);
        if(portraitInfo.isInital)
        {
            currentPortraitSprite.alpha = 0;
            //If this portrait is called later, do not perform tween
            portraits[currentPortraitName].isInital = false;
            if(portraitInfo.isOnRight)
            {
                currentPortraitSprite.x += 20;
                FlxTween.tween(currentPortraitSprite,{x:x-20,alpha:1,type:ONESHOT});
            }
            else
            {
                currentPortraitSprite.x -= 20;
                FlxTween.tween(currentPortraitSprite,{x:x+20,alpha:1,type:ONESHOT});
            }     
        }
        currentPortraitSprite.setGraphicSize(Std.int(portraitInfo.sizeFactor*currentPortraitSprite.width));
        currentPortraitSprite.updateHitbox();
        dialogueIndex++;
    }
	/**
	 * This function breaks the given graphic down into smoothening number of pieces
     * Then reveals the pieces in an animated fashion,similar to an integral.
     * Note: large values of smoothening (>10) may cause glitches,make sure to test
     * when using this function, 
	 */
	public function dropDownAnimate(path:String, smoothening:Int, xOffset:Int = 0, yOffset:Int = 0,
        sizeFactor:Float = 1.0):FlxSpriteGroup
    {
        var a = new FlxSprite(0, 0).loadGraphic(path);
        var sArr:FlxSpriteGroup = new FlxSpriteGroup(0,0);
        var j:Int = smoothening;
        for (i in 0...j)
        {
            var b = new BitmapData(Std.int(a.width), Std.int(a.height / j));
            b.copyPixels(a.pixels, new Rectangle(0, (i * a.height) / j, a.width, a.height / j), new Point(0, 0));
            var c = new FlxSprite(xOffset, ((i * a.height) / j) + yOffset, b);
            c.alpha = 0;
            c.setGraphicSize(Std.int(c.width*sizeFactor));
            c.updateHitbox();
            sArr.add(c);
        }
        var k:Int = 0;
        new FlxTimer().start(0.15 / j, function(tmr:FlxTimer)
        {
            sArr.members[k].alpha = 1;
            ++k;
        }, j);
        return sArr;
    }
    
}

/**
 * Helper class to hold information about 
 * Portraits - The icons for characters during dialogue
 */
class Portrait extends GraphicItem
{
	public var isOnRight:Bool;
	public var textColor:FlxColor;
    public var isInital:Bool;
	public function new(pathName:String,isOnRight:String = "left",textColor:String = "BLACK",keyWord:String = "Null",
        x:String = '0',y:String = '0',sizeFactor:String = '1.0')
	{
        super(pathName,x,y,sizeFactor);
		if(isOnRight.toLowerCase() == "right")
		{
			this.isOnRight = true;
		}
		else
		{
			this.isOnRight = false;
		}
		this.textColor =  FlxColor.fromString(textColor);
        if(keyWord.toLowerCase() == "inital")
        {
            this.isInital = true;
        }
        else
        {
            this.isInital = false;
        }    
	}
}

/**
 * Helper class for holding information of non-animated graphics
 */
class GraphicItem
{
    public var pathName:String;
    public var xOffset:Int;
    public var yOffset:Int;
    public var sizeFactor:Float;
    public function new(pathName:String,x:String = '0',y:String = '0',sizeFactor:String = '1.0')
    {
        this.pathName = pathName;
        this.xOffset = Std.parseInt(x);
        this.yOffset = Std.parseInt(y);
        this.sizeFactor = Std.parseFloat(sizeFactor);
    }
}