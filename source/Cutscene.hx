package;

import flixel.addons.text.FlxTypeText;
import flixel.system.FlxSound;
import DialogueBox.GraphicItem;
import haxe.Log;
import polymod.format.ParseRules.PlainTextParseFormat;
import polymod.format.ParseRules.TextFileFormat;
import haxe.io.Output;
import openfl.net.FileReference;
import flixel.ui.FlxButton;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;


class Cutscene extends FlxState
{
    public static var filePath:String;
    private var cutscenes:Array<Scene>;
    private var dropText:FlxTypeText;
    override function create()
    {
        super.create();
        FlxG.sound.music.stop();
        var textFileParser = CoolUtil.coolTextFile(filePath);

        for(i in 0...textFileParser.length)
        {
            var sceneInfo = [null,null,null,null,null,null,null];
            var temp = textFileParser[i].split(",");
            for(j in 0...temp.length)
            {
                sceneInfo[j] = temp[j];
            }
            sceneInfo[0] = Paths.txt(sceneInfo[0]);
            var scene = new Scene(sceneInfo[0],sceneInfo[1],sceneInfo[2],sceneInfo[3],sceneInfo[4],
                sceneInfo[5],sceneInfo[6]);
            cutscenes.push(scene);
        }

        trace("I got into Cutscene");

        var blackBox = new FlxSprite(0,0).makeGraphic(40,40,FlxColor.BLACK);
        blackBox.alpha = 0.6;
        add(blackBox);

		dropText = new FlxTypeText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = 'Pixel Arial 11 Bold';
		dropText.color = 0xFFD89494;
        add(dropText);

        updateScene(cutscenes[index]);

        /*new FlxTimer().start(3.0,function(tmr:FlxTimer)
        {
        });*/
    }
    private var index:Int = 0;
    private var picture:FlxSprite  = null;
    private var currentMusic:FlxSound;
    private var currentVocals:FlxSound;

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(PlayerSettings.player1.controls.ACCEPT)
        {
            if(index > cutscenes.length)
            {
                updateScene(cutscenes[index]);
            }
            else
            {
                LoadingState.loadAndSwitchState(new PlayState(), true);
            }
        }
    }
    private function updateScene(currentScene:Scene)
    {
        if(picture != null)
        {
            remove(picture);
        }
        picture = new FlxSprite(currentScene.xOffset,currentScene.yOffset).loadGraphic(
            currentScene.pathName);

        picture.setGraphicSize(Std.int(picture.width*currentScene.sizeFactor));

        add(picture);

        dropText.resetText(currentScene.dialogue);

        currentMusic.destroy();
        currentVocals.destroy();

        currentMusic = currentScene.music;
        currentVocals = currentScene.vocals;

        currentMusic.play();
        currentVocals.play();

        ++index;
    }
}
class Scene extends GraphicItem
{
    public var music:FlxSound;
    public var vocals:FlxSound;
    public var dialogue:String;
    public function new(pathName:String,x:String = '0',y:String = '0',sizeFactor:String = '1.0',
        musicPath:String,vocalsPath:String,dialogue:String)
    {
        super(pathName,x,y,sizeFactor);
        music.loadEmbedded(musicPath,true);
        vocals.loadEmbedded(vocalsPath);
        this.dialogue = dialogue;
    }
}
