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

int triad_dict[0][0];
[0, 4, 7] @=> triad_dict["dom"];
[0, 4, 7] @=> triad_dict["maj"];
[0, 3, 7] @=> triad_dict["min"];
[0, 4, 8] @=> triad_dict["aug"];
[0, 3, 6] @=> triad_dict["dim"];
[0, 5, 7] @=> triad_dict["sus"];

int seventh_dict[0];
10 => seventh_dict["dom"];
11 => seventh_dict["maj"];
10 => seventh_dict["min"];
10 => seventh_dict["aug"];
9  => seventh_dict["dim"];
10 => seventh_dict["sus"];

fun int getRoot(string input)
{
    int root;
    int alter;
    int chordtones[0];

    input => string curr;
    input.substring(0,1) => string first;
    if(pitch_dict.isInMap(first))
    {
        pitch_dict[first] => root;
    }
    else
    {
        <<<"Invalid root note (did you forget uppercase?)">>>;
        -999 => root;
    }
    input.erase(0,1);
    getRootAlter(input) => alter;
    return root + alter;
}

fun int getRootAlter(string input) // warning: destructive!
{
    0 => int alter;
    if(input.length() > 0)
    {
        input.substring(0,1) => string first;

        if(alter_dict.isInMap(first))
        {
            alter_dict[first] + alter => alter;
            input.erase(0,1);
            if(alter_dict.isInMap(input.substring(0,1)))
            {
                alter_dict[first] + alter => alter;
                input.erase(0,1);
            }
        }
    }
    return alter;
}

fun string getTriad(string input)
{
    if(input.length() >= 3)
    {
        input.substring(0,3) => string front;
        if(triad_dict.isInMap(front))
        {
            input.erase(0,3);
            return front;
        }
        else
        {
            if(Std.atoi(input.substring(0,1)) != -1)
            {
                return "dom";
            }
            else
            {
                return "maj";
            }
        }
    }
    if(input.length() > 0)
    {
        if(Std.atoi(input.substring(0,1)) != -1)
        {
            return "dom";
        }
        else
        {
            return "maj";
        }
    }
    else
    {
        return "maj";
    }

}

fun int[] getExtension(string input, string triad)
{
    int ans[0];
    0 => int alter;

    if(triad_dict.isInMap(triad))
    {
        triad_dict[triad] @=> ans;
    }
    if(input == "")
    {
        return ans;
    }
    //<<<"just triad">>>;
    //for(auto x : ans)
    //{
    //    <<<x>>>;
    //}
    else
    {
        while(input.length() > 0)
            {
                input.substring(0,1) => string first;
                if(alter_dict.isInMap(first))
                {
                    //<<<"found an alter symbol">>>;
                    alter_dict[first] => alter;
                    //<<<alter>>>;
                    input.erase(0,1);
                }
                if(input.length() >= 4 && input.substring(0,4) == "Maj7")
                {
                    ans << seventh_dict["maj"];
                    input.erase(0,4);
                }
                if(first == "7")
                {
                    //<<<"adding 7th">>>;
                    ans << seventh_dict[triad];
                    //for(auto x : ans)
                    //{
                    //    <<<x>>>;
                    //}
                    input.erase(0,1);
                }
                if(first == "9")
                {
                    //<<<"adding 9th">>>;
                    if(ans.size() == 3)
                    {
                        ans << seventh_dict[triad];
                    }
                    ans << 14 + alter;
                    //for(auto x : ans)
                    //{
                    //    <<<x>>>;
                    //}
                    input.erase(0,1);
                }
                if(input.length() >= 2 && input.substring(0,2) == "11")
                {
                    //<<<"adding 11th">>>;
                    if(ans.size() == 3)
                    {
                        ans << seventh_dict[triad];
                        ans << 14;
                    }
                    ans << 17 + alter;
                    //for(auto x : ans)
                    //{
                    //    <<<x>>>;
                    //}
                    input.erase(0,2);
                }
                if(input.length() >= 2 && input.substring(0,2) == "13")
                {
                    //<<<"adding 13th">>>;
                    if(ans.size() == 3 && input.length() == 2)
                    {
                        ans << seventh_dict[triad];
                        ans << 14;
                    }
                    ans << 21 + alter;
                    //for(auto x : ans)
                    //{
                    //    <<<x>>>;
                    //}
                    input.erase(0,2);
                }
            }
        return ans;
    }
}

fun int[] parseChord(string input)
{
    int temp[];
    string triad;
    getRoot(input) => int root;
    getTriad(input) => triad; 
    getExtension(input, triad) @=> temp;
    int ans[0];
    if(temp.size() > 1)
    {
        for(int i; i < temp.size()-1; i++)
        {
            if(temp[i] != temp[i + 1])
            {
                ans << temp[i] + root;
            }
        }
        ans << temp[-1] + root;
    }
    if(temp.size() == 1)
    {
        ans << temp[0] + root;
    }
    ans.sort();
    return ans;
}


fun void testParse(string input)
{
    string triad;
    int ans[];
    <<<input>>>;
    getRoot(input) => int root;
    <<<"root: ", root>>>;
    <<<input>>>;
    getTriad(input) => triad; 
    <<<"triad type: ", triad>>>;
    <<<input>>>;
    getExtension(input, triad) @=> ans;
    ans.sort();
    <<<"final chord tones: ">>>;
    for(auto x : ans)
    {
        <<<x>>>;
    }
    <<<input>>>;
}


/////////////////////////////////////////////////////////////////////////////
// testing
string testStrings[0];
testStrings << "A";
testStrings << "Bmin";
testStrings << "C##7";
testStrings << "D#dimMaj7";
testStrings << "Esus13b9";
testStrings << "Gbaug7#9";
testStrings << "Abmaj9#11";
testStrings << "B7b9#9b13";

// "Gbmaj7#11" = "G" + "b" + "maj" + "7#11"
// pitch + accidental + triad + extension
// pitch is always 1 character, accidental is 0-2 characters, triad is 0 or 3 characters, extension is arbitrarily long
Rhodey r => JCRev rev => dac;
.5 => r.gain;
.15 => rev.mix;


for(int i; i < testStrings.size(); i++)
{
    <<<"test ", i, "(", testStrings[i],"): ">>>;
    <<<"----------------------------">>>;
    parseChord(testStrings[i]) @=> int ans[];
    for(auto x : ans)
    {
        <<<x>>>;
        Std.mtof(48 + x) => r.freq;
        .5 => r.noteOn;
        100::ms => now;
    }
    <<<"----------------------------">>>;
    800::ms => now;
}
