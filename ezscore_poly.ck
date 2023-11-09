///////////////////////////////////////////////////////////////////////
// EZ score: score4-style notation input
///////////////////////////////////////////////////////////////////////
// This file introduces a way to quickly and easily input notes and rhythms,
// based primarily on the SCORE4 system. Pitches and rhythms are assigned
// as strings. These are parsed in the Melody class and interpreted as
// an int array of MIDI notes (pitch) and a float array for durations
// (not ChucK durations, but beat values).
// 
//
// Alex Han 2023

public class EZscore
{
    // member variables
    0 => int n_voices;
    int length;
    float totalDuration;
    
    int pitches[][];
    float durations[];

    //---------------------------------------------------------------------
    // helper functions
    //---------------------------------------------------------------------
    fun string clean_input(string input)
    {
        input.replace("//", " ");
        <<<input>>>;
        input.find("[") => int braceL;
        input.substring(0, braceL) => string prefix;
        if(prefix != "")
        {
            <<<"key signature: ", prefix>>>;
        }
        input.substring(braceL + 1) => string raw;
        if(!(raw.substring(raw.length()-1,1) == "]") )
        {
            <<<"poorly formatted input - must be surrounded by brackets">>>;
        }
        else
        {
            raw.substring(0, raw.length()-1) => raw;
        }
        return raw;
    }

    fun string[] split_delim(string input, string delim)
    {
        input => string copy;
        0 => int count;

        for(int i; i < copy.length(); i++)
        {
            if(copy.substring(i, 1) == delim)
            {
                count++;
            }
        }
        //count++;
        //<<<count>>>;
        0 => int j;

        string out[count+1];

        while(copy.find(delim) != -1)
        {
            copy.find(delim) => int ix;
            copy.substring(0, ix) => string curr;
            //<<<curr>>>;
            curr => out[j];
            copy.substring(ix + 1) => copy;
            //<<<copy>>>;
            j++;
        }
        if (copy.length() > 0) 
        {
            copy => out[j];
        }


        return out;
    }
    //---------------------------------------------------------------------
    /// RHYTHM PARSING
    //---------------------------------------------------------------------
    ["s", "e", "q", "h", "w"] @=> string durationLabels[];
    [.25, .5, 1.0, 2.0, 4.0] @=> float durationVals[];
    float durationMap[5];
    for (int i; i< durationVals.size(); i++)
    {
        durationVals[i] => durationMap[durationLabels[i]];
    }

    fun float parseDuration(string input)
    {
        0 => int dots;
        0 => int isTriplet;
        float value;

        if(Std.atof(input) != 0)
        {
            Std.atof(input) => value;
        }
        else
        {
            for(int i; i < input.length(); i++)
            {
                input.substring((i,1)) => string curr;
                if(curr == "t")
                {
                    1 => isTriplet;
                }        
                if(curr == ".")
                {
                    dots++;
                }
                if(curr == "s" || curr == "e" || curr == "q" || curr == "h" || curr == "w")
                {
                    durationMap[curr] => value;
                }
            }
            if(isTriplet == 1)
            {
                value * 2/3 => value;
            }
            0 => float add;
            if(dots > 0)
            {
                for(int i; i < dots + 1; i++)
                {
                    value*Math.pow(.5, i) +=> add;
                }
                value * add => value;
            }
        }

        return value;

    }
    fun float[] parse_rhythm(string raw)
    {
        clean_input(raw) => string input;
        for(int i; i < input.length(); i++)
        {
            if(input.substring(i, 1) == "x")
            {
                input.substring(0, i) => string LH;
                //<<<"LH: ", LH>>>;
                LH.substring(LH.rfind(" ") + 1) => string temp;
                //<<<"to clone: ", temp, " length: ", temp.length()>>>;
                " " => string toclone;
                toclone.insert(0, temp);
                //<<<"to clone (w space): ", toclone, " length: ", toclone.length()>>>;
                input.substring(i) => string RH;
                //<<<"RH: ", RH>>>;
                RH.substring(1, RH.find(" ") - 1) => string numStr;
                numStr.toInt() => int num;
                //<<<"num: ", num>>>;
                "" => string newstr;
                for (0 => int j; j < num; j++)
                {
                    newstr + toclone => newstr;
                }
                newstr.rtrim() => newstr;
                //<<<"newstr: ", newstr>>>;
                input.replace(i-(toclone.length()-1), RH.find(" ")+(toclone.length()-1), "");
                //<<<"trimmed input: ", input>>>;
                input.insert(i-(toclone.length()-1), newstr);
                //<<<"with inserted newstr: ", input>>>;
            }
        }
        split_delim(input, " ") @=> string strOut[];
        float output[0];
        for(auto i : strOut)
        {
            output << parseDuration(i);
        }
        return output;
    }
    //---------------------------------------------------------------------
    /// PITCH PARSING
    //---------------------------------------------------------------------
    ["c", "d", "e", "f", "g", "a", "b", "r"] @=> string base_pitches[];
    [12, 14, 16, 17, 19, 21, 23, -999] @=> int base_notes[];
    int pitch_map[7];

    for (int i; i < base_pitches.size(); i++)
    {
        base_notes[i] => pitch_map[base_pitches[i]];
    }

    fun int[] getKeyVector(string key)
    {
        int keyVector[7];
        keyVector.zero();

        if(key.length() == 3)
        {
            key.substring(2,1) => string type;
            Std.atoi(key.substring(1,1)) => int n;
            //<<<"type: ", type, " n: ", n>>>;

            if(type == "s")
            {
                for(int i; i < n; i++)
                {
                    1 => keyVector[i];
                }
            }
            if(type == "f")
            {
                for(7 - n => int i; i < 7; i++)
                {
                    -1 => keyVector[i];
                }
            }
        }

        return keyVector;
    }

    fun int[][] parse_pitch(string input)
    {
        int output[0][0];

        // extract key signature information
        split_delim(clean_input(input), " ") @=> string split[];
        int keyVector[7];
        keyVector.zero();
        if(split[0].substring(0,1) == "k")
        {
            getKeyVector(split[0]) @=> keyVector;  // return the vector of alters
            split.erase(0);
        }

        // build associative array: key = pitch (string), value = alter (-1, 0, or 1)
        ["f", "c", "g", "d", "a", "e", "b"] @=> string circleFifths[];
        int key[0];
        for (int i; i < 7; i++)
        {
            keyVector[i] => key[circleFifths[i]];
        }
        4 => int octave;
        999 => int last;

        for(auto item : split) // for each element in input list
        {
            int chord[0];
            split_delim(item, ":") @=> string curr_split[];
            for (auto curr : curr_split)
            {
                0 => int step;
                0 => int alter;
                int pitch;
                0 => int octFlag;
                0 => int dirFlag;
                // future: need to check if "first" is indeed a valid pitch/step
                curr.substring(0,1) => string first;
                pitch_map[first] => step;
                if(key.isInMap(first)) 
                {
                    key[first] => alter; // apply key signature from key vector
                }
                curr.erase(0,1);
                step + alter => pitch;
                if(curr.length() == 0 && pitch > 0) // if no more flags after step/alter, check proximity for octave
                {
                    if(pitch - last > 6)
                    {
                        //octave--;
                    }
                    if(pitch - last <= -6)
                    {
                        //octave++;
                    }
                }
                while(curr.length() > 0) // go through each character in element
                {
                    curr.substring(0,1) => first;
                    //handle alter flag if there
                    if(first == "f")
                    {
                        -1 => alter;
                    }
                    if(first == "s")
                    {
                        1 => alter;
                    }
                    if(first == "n")
                    {
                        0 => alter;
                    }
                    // handle explicit octave number flag
                    if(first.toInt() != 0)
                    {
                        Std.atoi(first) => octave;
                        1 => octFlag;
                    }
                    // handle interval direction flags (octave flag overrides)
                    if(first == "u" && octFlag == 0)
                    {
                        if(pitch - last <= 6)
                        {
                            octave++;
                        }
                        1 => dirFlag;
                    }
                    if(first == "d" && octFlag == 0)
                    {
                        if(pitch - last > -6)
                        {
                            octave--;
                        }
                        1 => dirFlag;
                    }
                    curr.erase(0,1);
                }
                // set octave based on proximity--tritone always favors higher octave
                // direction flag (and octave flag) overrides
                if (octFlag == 0 && dirFlag == 0 && pitch > 0)
                {
                    if(pitch - last > 6)
                    {
                        octave--;
                    }
                    if(pitch - last <= -6)
                    {
                        octave++;
                    }
                }
                if (step > 0)
                {
                    step + alter => last;
                }
                chord << step + alter + 12*octave;
            }
            if(chord.size() > n_voices)
            {
                chord.size() => n_voices;
            }
            output << chord;
        }
        return output;
    }
    // midi note to pitch
    ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"] @=> string chromatic[];
    fun string mid2str(int note)
    {
        if(note < 0)
        {
            return "rest";
        }
        else
        {
            note % 12 => int step;
            (note - step) / 12 => int octave;
            chromatic[step] => string name;
            name + Std.itoa(octave) => name;

            return name;
        }
    }
    // API 
    


    fun void setPitch(string input)
    {
        parse_pitch(input) @=> pitches;
        pitches.size() => length;
    }
    fun void setRhythm(string input)
    {
        parse_rhythm(input) @=> durations;
        durations.size() => length;
        0 => float sum;
        for(auto i : durations)
        {
            i +=> sum;
        }

        sum => totalDuration;
    }

    fun int countNotes()
    {
        int count;
        for(int i; i < length; i++)
        {
            pitches[i].size() +=> count;
        }
        return count;
    }

    fun float getTotalDur()
    {
        return totalDuration;
    }
    fun int[][] getPitches()
    {
        return pitches;
    }
    fun float[] getRhythm()
    {
        return durations;
    }

    fun int getLowestNote()
    {
        999 => int lowest;

        for (int i; i < pitches.size(); i++)
        {
            pitches[i] @=> int curr[];
            for (auto x : curr)
            {
                if (x < lowest && x >= 0)
                {
                    x => lowest;
                }
            }

        }

        return lowest;
    }
    fun int getHighestNote()
    {
        -999 => int highest;

        for (int i; i < pitches.size(); i++)
        {
            pitches[i] @=> int curr[];
            for (auto x : curr)
            {
                if (x > highest && x >= 0)
                {
                    x => highest;
                }
            }
        }

        return highest;
    }

    fun void printPitches()
    {
		<<<"# of pitches: ", pitches.size()>>>;
        for (int i; i < pitches.size(); i++)
        {
            pitches[i] @=> int curr[];
            for(auto p : curr)
            {
                <<<p>>>;
            }

        }
    }
    fun void printRhythms()
    {   
		<<<"# of durations: ", durations.size()>>>;
        for(auto r : durations)
        {
            <<<r>>>;
        }
    }

	fun void printBoth()
	{
		for(int i; i < durations.size(); i++)
		{
            pitches[i] @=> int curr[];
            chout <= "note: ";
            for(auto x : curr)
            {
                chout <= mid2str(x) <= " ";
            }
            chout <= IO.newline() <= "duration: " <= durations[i] <= IO.newline();
		}
	}

}

//---------------------------------------------------------------------
// Testing
//---------------------------------------------------------------------

"[ef4 efu d bf c d ef efd cu bf]" => string rainbow;
//"k2s[roll/f4:a:du/ r g5 f e f a g f g a r a b c d a f a g f g a g es f]" => string mozart_p;
//[roll/fs4:a:du/ r g5 fs e fs a g fs g a r a b cs d a fs a g fs g a g es fs]" => string mozart_p;
"[k2s f4:a:du r e:g d:fs c:e d:fs f:a e:g d:fs e:g d:f:a r a b csd d au fs f:a e:g d:fs e:g f:a g fs d]" => string mozart_p;
"[c5 e g bd cu d c a g cu gd f e f e]" => string mozart_p2;
"[h q q q. sx2 h h qx4 te te te q]" => string mozart_r2;
"[q q sx8 q q e e e e q q sx4 e e e q.]" => string mozart_r;
"[a5 r cu r ad bf gf ef bfu af f df afd gfu dn r fs e d cs e d d bfd g a f ef r du cs d f ef bd af dfu bfd r bf a af g bn a f e d f f d g r r]" => string coltrane_p;
"[a5 r c r a bf gf ef bfu af f df af gfu dn r fs e d cs e d d bf g a f ef r du cs d f ef b af df bf r bf a af g bn a f e d f f d g r r]" => string coltrane2_p;
"[ex25 q e q. q ex8 q ex6 ex7 q. h e]" => string coltrane_r;
"[k2f//f4//b du c bd eu df dn f//r e f e//r d e d c ad b du//c gd b a r b//g b du bd r//enu ef gfd b cu d//f bnd r afu r gf//gn e bd g du f]" => string anthropology_p1;
"[k2f//f4//b d c b e df dn f//r e f e//r d e d c a b d//c g b a r b//g b d b r//enu ef gfd b c d//f bnd r afu r gf//gn e b g du f]" => string anthropology_p2;
"[e//ex8//q. q e q//e ex7//ex4 q. q.//ex5//q q q e e e//q. e ex4//ex4 e q]" => string anthropology_r1;

// Cello
"[k5s b2 fu es f//fd fu f//bd fu f//fd fu f//b2 fu es f//fd fu f//bd fu f//fd fu es f]" @=> string cello_1_8;
"[q e e q//qx3//qx3//qx3//q e e q//qx3//qx3//q e e q]" @=> string cello_1_8_R;
"[k5s e3 bu a b//bd bu b//e3 bu a b//bd bu b//dd cu bs c//a2 cuu c//g du dn d//dd du d]" @=> string cello_9_16;
"[q e e q//qx3//q e e q//qx3//q e e q//qx3//q e e q//q q q]" @=> string cello_9_16_R;
"[k5s e3 bu a b//bd bu b//ed bu b//bd bu b//dd cu c//a2 cuu c//b2 fu f//bd es es]" @=> string cello_17_24;
"[q e e q//qx3//qx3//qx3//qx3//qx3//qx3//q q q]" @=> string cello_17_24_R;
"[k5s b2 fu f//d au a//g du dn d f//c3 bu b//cd gu g//cd gu g//f cu c//fd cu c]" @=> string cello_25_32;
"[qx3//qx3//q ex4//qx3//qx3//qx3//qx3//q q q]" @=> string cello_25_32_R;
"[k5s b2 fu f//d au a//g du d//c3 bu b//c3 gu g//cd gu g//f cu c//fd cu c]" @=> string cello_33_40;
"[qx3//qx3//qx3//qx3//qx3//qx3//qx3//q q q]" @=> string cello_33_40_R;
"[k5s r r r r r r r r]" @=> string cello_41_48;
"[h.x7 h.]" @=> string cello_41_48_R;
"[k5s r r r r r r r//r e2 gn cn an]" @=> string cello_49_56;
"[h.x7//q e e e e]" @=> string cello_49_56_R;

[cello_1_8, cello_9_16, cello_17_24, cello_25_32, cello_33_40, cello_41_48, cello_49_56] @=> string cello_pitch[];
[cello_1_8_R, cello_9_16_R, cello_17_24_R, cello_25_32_R, cello_33_40_R, cello_41_48_R, cello_49_56_R] @=> string cello_rhythm[];

// Viola
"[k5s r d4 dn d//r d d//r d d//r d d//r d dn d//r d d//r d d//r d dn d]" @=> string viola_1_8;
"[q e e q//qx3//qx3//qx3//q e e q//qx3//qx3//q e e q]" @=> string viola_1_8_R;
"[k5s r r an4 g gn g//r g g//r r g gn f g//r gn g//r r gn f es f//r f f//r r cu cn b cn//r cn cn]" @=> string viola_9_16;
"[e s s e e q//qx3//e s s e e q//qx3//e s s e e q//qx3//e s s e e q//q q q]" @=> string viola_9_16_R;
"[k5s r r r r r r r r]" @=> string viola_17_24;
"[h.x7 h.]" @=> string viola_17_24_R;
"[k5s r r r r r r r r]" @=> string viola_25_32;
"[h.x7 h.]" @=> string viola_25_32_R;
"[k5s r r r r r r r r]" @=> string viola_33_40;
"[h.x7 h.]" @=> string viola_33_40_R;
"[k5s r r cn4 b a b d//g f//r r b4 a g a d//f e//r r an4 g gn g c//e f e d c c dn//d//f e d e f es f g a]" @=> string viola_41_48;
"[e s s ex4//q h//e s s ex4//q h//e s s ex4//ex4 e s s//h.//q sx4 s s s s]" @=> string viola_41_48_R;
"[k5s r r r r r r r r]" @=> string viola_49_56;
"[h.x7 h.]" @=> string viola_49_56_R;

[viola_1_8, viola_9_16, viola_17_24, viola_25_32, viola_33_40, viola_41_48, viola_49_56] @=> string viola_pitch[];
[viola_1_8_R, viola_9_16_R, viola_17_24_R, viola_25_32_R, viola_33_40_R, viola_41_48_R, viola_49_56_R] @=> string viola_rhythm[];

// Violin II
"[k5s r r gn4 f es f//r g g//r a a//r g g//r r gn f es f//r g g//r a a//r g gn g]" @=> string violinII_1_8;
"[e s s e e q//qx3//qx3//qx3//e s s e e q//qx3//qx3//q e e q]" @=> string violinII_1_8_R;
"[k5s r//r e4 d e bu//e r r//r ed d e bu//d r r//r//r//r]" @=> string violinII_9_16;
"[h.//q ex4//qx3//q ex4//qx3//h.//h.//h.]" @=> string violinII_9_16_R;
"[k5s r r an4 g gn g//r g g//r r g gn f gn//r gn gn//r r gn f es f//r f f//r r b a an a//r g g]" @=> string violinII_17_24;
"[e s s e e q//qx3//e s s e e q//qx3//e s s e e q//qx3//e s s e e q//q q q]" @=> string violinII_17_24_R;
"[k5s r r gn4 f es f//r f f//r cnu b cn ef//r gd g//e f g//g a b bs//c d e r fn e//d e c d b c b a]" @=> string violinII_25_32;
"[e s s e e q//qx3//q ex4//qx3//qx3//q q e e//e e q e s s//ex4 s s s s]" @=> string violinII_25_32_R;
"[k5s r r gn4 f es f//r f f//r bs bs//r g4 g//e f g//g a b bs//c d e r bu//c f f]" @=> string violinII_33_40;
"[e s s e e q//qx3//qx3//qx3//qx3//q q e e//e e q e e//q q q]" @=> string violinII_33_40_R;
"[k5s r d5 d//r c bs c gu//r cd c//r b a b fu//r bd b//r a an a eu//r ad a//r an g an d5]" @=> string violinII_41_48;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q e e e e]" @=> string violinII_41_48_R;
"[k5s r d5 d//r c bs c gu//r cd c//r cn b cn f//r b4 b//r a an a c//r b b//r b b]" @=> string violinII_49_56;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q q q]" @=> string violinII_49_56_R;

[violinII_1_8, violinII_9_16, violinII_17_24, violinII_25_32, violinII_33_40, violinII_41_48, violinII_49_56] @=> string violinII_pitch[];
[violinII_1_8_R, violinII_9_16_R, violinII_17_24_R, violinII_25_32_R, violinII_33_40_R, violinII_41_48_R, violinII_49_56_R] @=> string violinII_rhythm[];

// Violin I
"[k5s f5//r//r//r e d e//f//r//r//d e f e a4 b]" @=> string violinI_1_8;
"[h.//h.//h.//q. e e e//h.//h.//h.//ex4 e e]" @=> string violinI_1_8_R;
"[k5s d5 f c cn b//r r a b//d f c cn b//r r b c//a c d e es//f e f//d//r f e a4 b]" @=> string violinI_9_16;
"[q. e e s s//q q e e//q. e e s s//q q e e//h sx4//h e e//h.//q e e e e]" @=> string violinI_9_16_R;
"[k5s d5 f c cn b//r r a b//d f c cn b//r r b c//a r r//f g a c//d//r]" @=> string violinI_17_24;
"[q. e e s s//q q e e//q. e e s s//q q e e//qx3//q q e e//h.//h.]" @=> string violinI_17_24_R;
"[k5s d5 e f//cu a g//f g d//f e d e//c d e//es f g an//a b c r b//a b g a f g f e]" @=> string violinI_25_32;
"[qx3//qx3//qx3//q e e q//qx3//q q e e//e e q e e//ex4 s s s s]" @=> string violinI_25_32_R;
"[k5s d5 b e b fu d//c6 a g f d//f bs4 gu bsd d bs//fu gd eu d e gd//c d e//es f g an//a b c r d//e f5 f es f]" @=> string violinI_33_40;
"[ex6//q ex4//ex6//ex6//qx3//q q e e//e e q e e//q q e s s]" @=> string violinI_33_40_R;
"[k5s g5 r bd//a r gu//f r ad//b//e r b//a b a g c gu//f//an4 g an b c b c d e d e f]" @=> string violinI_41_48;
"[h e e//h e e//h e e//h.//h e e//s s e q e e//h.//sx8 s s s s]" @=> string violinI_41_48_R;
"[k5s g5//a b c g gu//f e d e f//cn6 an b an g du//e r b//a b a g a//b//r an e]" @=> string violinI_49_56;
"[h.//e e q e e//q ex4//q s s e e e//h r e//s s e q q//h.//r q q]" @=> string violinI_49_56_R;

[violinI_1_8, violinI_9_16, violinI_17_24, violinI_25_32, violinI_33_40, violinI_41_48, violinI_49_56] @=> string violinI_pitch[];
[violinI_1_8_R, violinI_9_16_R, violinI_17_24_R, violinI_25_32_R, violinI_33_40_R, violinI_41_48_R, violinI_49_56_R] @=> string violinI_rhythm[];

// Flute
"[k5s r r r r r r r r]" @=> string flute_1_8;
"[h.x7 h.]" @=> string flute_1_8_R;
"[k5s r r r r r//a6 f f e d c//r g bs d g//bs g e f e d bs c]" @=> string flute_9_16;
"[h.x5//ex6//q ex4//e e sx4 e e]" @=> string flute_9_16_R;
"[k5s d6 r g gn//g f e//r gn f//g gn e d e d c b c//a r r//f g a c//d//r]" @=> string flute_17_24;
"[q q e e//h e e//h e e//s s e sx4 e e//qx3//q q e e//h.//h.]" @=> string flute_17_24_R;
"[k5s r r r r r r//r r b6//a b g a f g f e]" @=> string flute_25_32;
"[h.x6//h e e//ex4 s s s s]" @=> string flute_25_32_R;
"[k5s d5 bu d d d dn d//fd du f f f es f//d f gd//b g e d//c d e//es f g an//a b c r d//e esu es]" @=> string flute_33_40;
"[ex4 s s e//ex4 s s e//qx3//q q e e//qx3//q q e e//e e q e e//q q q]" @=> string flute_33_40_R;
"[k5s r r r r r r r r]" @=> string flute_41_48;
"[h.x7 h.]" @=> string flute_41_48_R;
"[k5s f5//g a b g fu//e d c d e//a5 gn an gn d dnu//d r b//g a g f g b//dn b d b an//gn f e dn]" @=> string flute_49_56;
"[h./e e q e e//q ex4//q s s ex3//h e e//s s e q e e//q s s e q//q q e e]" @=> string flute_49_56_R;

[flute_1_8, flute_9_16, flute_17_24, flute_25_32, flute_33_40, flute_41_48, flute_49_56] @=> string flute_pitch[];
[flute_1_8_R, flute_9_16_R, flute_17_24_R, flute_25_32_R, flute_33_40_R, flute_41_48_R, flute_49_56_R] @=> string flute_rhythm[];

// Tuba
"[k5s r r r r r r r r]" @=> string tuba_1_8;
"[h.x7 h.]" @=> string tuba_1_8_R;
"[k5s r e3 d e//r e e//r e d e//r e e//r d dn d//r d d//r g gn g//r g g]" @=> string tuba_9_16;
"[q e e q//qx3//q e e q//qx3//q e e q//qx3//q e e q//q q q]" @=> string tuba_9_16_R;
"[k5s r e3 d e//r e e//r e d e//r e e//r d dn d//r d d//r d d//r d d]" @=> string tuba_17_24;
"[q e e q//qx3//q e e q//qx3//q e e q//qx3//qx3//q q q]" @=> string tuba_17_24_R;
"[k5s r d3 dn d//r d d//r g gn g b//r e3 e//r c c//r es es//r//r]" @=> string tuba_25_32;
"[q e e q//qx3//q ex4//qx3//qx3//qx3//h.//h.]" @=> string tuba_25_32_R;
"[k5s r d3 dn d//r d d//r g g//r e e//r r r r]" @=> string tuba_33_40;
"[q e e q//qx3//qx3//qx3//h. h. h. h.]" @=> string tuba_33_40_R;
"[k5s e2 g3:b g:b//e2 a3:g4 a3n:gn4 a3:g4 d4:c5//d2 f3:a f:a//d2 f3:an es:g f:an b:e//c2 e3:g e:g//c2 f3:e4 es3:d4 f3:e4 d4:a4//b1 d3:f d:f//cn2 d3:f dn:es d:f an3:d4]" @=> string tuba_41_48;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q e e e e]" @=> string tuba_41_48_R;
"[k5s e2 g3:b g:b//e2 a3:g4 a3n:gn4 a3:g4 d4:c5//d2 f3:a f:a//d2 f3:an es:g f:an an:cn//c2 e3:g e:g//c2 e3:gn d:f e:gn gn:cn//cn2 e3:gn e:gn//cn2 e3 e]" @=> string tuba_49_56;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q q q]" @=> string tuba_49_56_R;

[tuba_1_8, tuba_9_16, tuba_17_24, tuba_25_32, tuba_33_40, tuba_41_48, tuba_49_56] @=> string tuba_pitch[];
[tuba_1_8_R, tuba_9_16_R, tuba_17_24_R, tuba_25_32_R, tuba_33_40_R, tuba_41_48_R, tuba_49_56_R] @=> string tuba_rhythm[];


EZscore mozart;
mozart.setPitch(mozart_p);
mozart.setRhythm(mozart_r);
//mozart.n_voices => int N;

1 => int which;
EZscore inst[7];
for(int i; i < 7; i++)
{
    inst[which].setPitch(tuba_pitch[which]);
    inst[which].setRhythm(tuba_rhythm[which]);
}

//EZscore cello[7];
//cello[which].setPitch(cello_pitch[which]);
//cello[which].setRhythm(cello_rhythm[which]);

//cello[which].printBoth();
inst[which].n_voices => int N;
//<<<"max voices: ", N>>>;

//---------------------------------------------------------------------
// Testing playback
//---------------------------------------------------------------------

160 => float bpm;
// t = 60*n/bpm sec
SinOsc osc[N]; ADSR adsr[N];
Gain g => dac;
g.gain(.25);
for (int i; i < N; i++)
{
    osc[i] => adsr[i] => g;
    osc[i].gain(.5);
    adsr[i].set(10::ms, 500::ms, 0.0, 50::ms);
}

fun void play(int which, int note, float duration)
{
    if(note >= 0)
    {
        Std.mtof(note) => osc[which].freq;
        adsr[which].keyOn();
    }
}

fun void playStreams(int notes[][], float durations[])
{
    //need to also check that the note and duration streams are the same length
    for(int i; i < notes.size(); i++)
    {
        for(int j; j < notes[i].size(); j++)
        {
            spork ~ play(j, notes[i][j], durations[i]);
        }
        60*durations[i]/bpm => float durTime;
        durTime::second => now;
    }
}

//playStreams(inst[which].pitches, inst[which].durations);

//while(true)
//{
//    1::second => now;
//}

///////////////////////////////////////////////////////////////////////////////////////
// TO-DO:
// tied notes
// better debugging tools or ways to ensure valid line-up between pitch and rhythm
// measure flags -> force alignment?

// chords
// velocity stream

// on-screen type in 