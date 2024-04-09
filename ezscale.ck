public class EZscale
{
    int notes[];

    int pitch_dict[7];
    0 => pitch_dict["C"];
    2 => pitch_dict["D"];
    4 => pitch_dict["E"];
    5 => pitch_dict["F"];
    7 => pitch_dict["G"];
    9 => pitch_dict["A"];
    11 => pitch_dict["B"];

    int alter_dict[0];
    -1 => alter_dict["b"];
    1 => alter_dict["#"];

    int scaleDict[0][0];

    // greek modes
    [0, 2, 4, 5, 7, 9, 11] @=> scaleDict["ionian"];
    [0, 2, 3, 5, 7, 9, 10] @=> scaleDict["dorian"];
    [0, 1, 3, 5, 7, 8, 10] @=> scaleDict["phyrgian"];
    [0, 2, 4, 6, 7, 9, 11] @=> scaleDict["lydian"];
    [0, 2, 4, 5, 7, 9, 10] @=> scaleDict["mixolydian"];
    [0, 2, 3, 5, 7, 8, 10] @=> scaleDict["aeolian"];
    [0, 1, 3, 5, 6, 8, 10] @=> scaleDict["locrian"];

    // symmetric
    [0, 2, 4, 6, 8, 10] @=> scaleDict["wholetone"];
    [0, 3, 4, 7, 8, 11] @=> scaleDict["augmented"];
    [0, 1, 3, 4, 6, 7, 9, 10] @=> scaleDict["halfwhole"];
    [0, 2, 3, 5, 6, 8, 9, 11] @=> scaleDict["wholehalf"];

    // penta/hexa
    [0, 3, 5, 6, 7, 10] @=> scaleDict["blues"];
    [0, 2, 4, 7, 9] @=> scaleDict["majpentatonic"];
    [0, 3, 5, 7, 10] @=> scaleDict["minpentatonic"];
    [0, 2, 4, 7, 9, 11] @=> scaleDict["majhexatonic"];
    [0, 2, 3, 5, 7, 10] @=> scaleDict["minhexatonic"];

    // altered modes
    [0, 2, 4, 5, 7, 8, 11] @=> scaleDict["harmonicmajor"];
    [0, 2, 3, 5, 7, 8, 11] @=> scaleDict["harmonicminor"];
    [0, 2, 3, 5, 7, 9, 11] @=> scaleDict["melodicminor"];
    [0, 1, 4, 5, 7, 8, 10] @=> scaleDict["phyrgiandominant"];
    [0, 2, 4, 6, 7, 9, 10] @=> scaleDict["lydiandominant"];
    [0, 2, 4, 6, 8, 9, 11] @=> scaleDict["lydianaugmented"];
    [0, 2, 4, 5, 6, 8, 10] @=> scaleDict["majorlocrian"];
    [0, 1, 3, 4, 6, 8, 10] @=> scaleDict["supralocrian"];
    [0, 1, 3, 5, 7, 9, 11] @=> scaleDict["neapolitanmajor"];
    [0, 1, 3, 5, 7, 8, 11] @=> scaleDict["neapolitanminor"];
    [0, 2, 3, 5, 6, 8, 10] @=> scaleDict["halfdiminished"];

    // "exotic"
    [0, 1, 4, 5, 7, 8, 11] @=> scaleDict["doubleharmonic"];
    [0, 1, 4, 6, 8, 10, 11] @=> scaleDict["enigmatic"];
    [0, 2, 3, 6, 7, 8, 10] @=> scaleDict["gypsy"];
    [0, 2, 3, 6, 7, 8, 11] @=> scaleDict["hungarianminor"];
    [0, 3, 4, 6, 7, 9, 10] @=> scaleDict["hungarianmajor"];
    [0, 1, 4, 5, 6, 8, 11] @=> scaleDict["persian"];
    [0, 2, 4, 6, 9, 10] @=> scaleDict["prometheus"];
    [0, 1, 5, 7, 8] @=> scaleDict["inscale"];
    [0, 1, 5, 7, 10] @=> scaleDict["insen"];
    [0, 1, 5, 6, 10] @=> scaleDict["iwato"];
    [0, 3, 5, 7, 10] @=> scaleDict["yoscale"];


    fun EZscale(string name) 
    {
        scaleDict[name] @=> notes;
    }

    fun EZscale(string name, int root) 
    {
        scaleDict[name] @=> notes;
        for(int i; i < notes.size(); i++)
        {
            root +=> notes[i];
        }
    }

    fun EZscale(string name, string rootName) 
    {
        scaleDict[name] @=> notes;
        parseRoot(rootName) => int root;

        for(int i; i < notes.size(); i++)
        {
            root +=> notes[i];
        }
    }

    fun int parseRoot(string input)
    {
        int root;

        if(input.length() > 3)
        {
            <<<"poorly formatted input. String representing root should be max. 3 characters and have format 'step'+'alter'+'octave'">>>;
        }

        input.substring(0,1) => string step;
        if(pitch_dict.isInMap(step))
        {
            pitch_dict[step] => root;
        }
        else
        {
            <<<"Invalid root note (did you forget uppercase?)">>>;
            -999 => root;
        }        

        if(input.length() > 1)
        {
            if(alter_dict.isInMap(input.substring(1,1)))
            {
                alter_dict[input.substring(1,1)] +=> root;
            }
            if(Std.atoi(input.substring(1,1)) != -1)
            {
                Std.atoi(input.substring(1,1)) * 12 +=> root;
            }
            if(input.length() > 2 && Std.atoi(input.substring(2,1)) != -1)
            {
                Std.atoi(input.substring(2,1)) * 12 +=> root;
            }
        }

        return root;
    }

    fun int[] lookup(string name)
    {
        return scaleDict[name];
    }

    fun int degree(int note)
    {
        -1 => int ans;
        note % 12 => int pitch;
        for(int i; i < notes.size(); i++)
        {
            if(notes[i] % 12 == pitch)
            {
                i => ans;
            }
        }
        return ans;
    }
}

// int scaleDict[0][0];
// [0, 2, 4, 5, 7, 9, 11] @=> scaleDict["ionian"];
// [0, 2, 3, 5, 7, 9, 10] @=> scaleDict["dorian"];
// [0, 1, 3, 5, 7, 8, 10] @=> scaleDict["phyrgian"];
// [0, 2, 4, 6, 7, 9, 11] @=> scaleDict["lydian"];
// [0, 2, 4, 5, 7, 9, 10] @=> scaleDict["mixolydian"];
// [0, 2, 3, 5, 7, 8, 10] @=> scaleDict["aeolian"];
// [0, 1, 3, 5, 6, 8, 10] @=> scaleDict["locrian"];


// [0, 2, 4, 5, 7, 9, 11] @=> int testArr[];
// testArr.typeOf() @=> Type t;
// cherr <= "testArr is an: " <= t.name() <= IO.newline() <= "is an array: " <= t.isArray() <= IO.newline();


// scaleDict["ionian"].typeOf() @=> t;
// cherr <= "scaleDict['ionian'] is an: " <= t.name() <= IO.newline() <= "is an array: " <= t.isArray() <= IO.newline();

EZscale scale("minhexatonic", "C5");

//scale.lookup("minhexatonic") @=> int test[];

// for(auto x : scale.notes)
// {
//     <<<x>>>;
// }

<<<scale.degree(87)>>>;