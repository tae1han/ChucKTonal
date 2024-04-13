///////////////////////////////////////////////////////////////////////
// EZ score: score4-style notation input
// Tutorial examples - Playback and multi-part scores
//
// This file contains a ScorePlayer class meant to facilitate playback
// of EZscore objects. It also allows for stacking of multiple parts 
// to be played simultaneously.
//
// Alex Han 2024
///////////////////////////////////////////////////////////////////////

// Custom class for EZscore playback

class ScorePlayer
{
    EZscore score;
    int pitches[][];
    float rhythms[];

    int n_voices;
    SinOsc oscs[];
    ADSR envs[];
    Gain bus;

    120 => float local_bpm;

    fun void init(EZscore s)
    {
        s @=> score;
        s.n_voices => n_voices;
        s.pitches @=> pitches;
        s.rhythms @=> rhythms;
        init_sound();
    }

    fun void init_sound()
    {
        SinOsc temp_oscs[n_voices] @=> oscs;
        ADSR temp_envs[n_voices] @=> envs;
        bus.gain(.2);
        for (int i; i < n_voices; i++)
        {
            oscs[i] => envs[i] => bus => dac;
            1 - (.2*n_voices) => oscs[i].gain;
            //oscs[i].gain(1/n_voices);
            envs[i].set(10::ms, 500::ms, 0.0, 50::ms);
        }
    }

    fun void playNote(int which, int note, float duration)
    {
        if(note >= 0)
        {
            Std.mtof(note) => oscs[which].freq;
            envs[which].keyOn();
        }
    }

    fun void play()
    {
        //need to also check that the note and duration streams are the same length
        for(int i; i < pitches.size(); i++)
        {
            for(int j; j < pitches[i].size(); j++)
            {
                spork ~ playNote(j, pitches[i][j], rhythms[i]);
            }
            60*rhythms[i]/local_bpm => float durTime;
            durTime::second => now;
        }
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
		<<<"# of rhythms: ", rhythms.size()>>>;
        for(auto r : rhythms)
        {
            <<<r>>>;
        }
    }

}

//---------------------------------------------------------------------
// Example: three part score
//---------------------------------------------------------------------

"[k5s d5 _d d c//gn4:b4:e5//f5 _f f e//e4:bu:e:gn5//gn5 d c _c b c//gnu d c _c b d//b4:e:g d f e d//d c]" @=> string V1_M_1_8_P;
"[q. _e e e//h.//q. _e e e//h.//e e e _e e e//e e e _e e e//q ex4//q. q.]" @=> string V1_M_1_8_R;

"[k5s r f4 e//r//f b an gn//e//gn gn//gn g//g _g a g f//f]" @=> string V2_M_1_8_P;
"[q e q.//h.//ex3 q.//h.//q. q.//q. q.//q _e ex3//h.]" @=> string V2_M_1_8_R;

//"[k5s f2:fu b2 bu f du fd gn2:gnu b2 bu ed eu ed//c2:cu gnu b cd eu gd bu bd e gd b bd//d2:du b bu f fu bd e2:eu b bu ed gnu bd//c2:cu gnu b cd eu gnd bu bd e gd b bd//ds2:du b bu gn du dn e2:eu b cu gn b bd//d2:du b bu fss du dd e2:eu b du gd b dd//c2:cu g bu ed eu b bu bd e gd b ed//f2:fu e bu g fu c3 f2:fu e a f fu cd]" @=> string V3_M_1_8_P;
"[k5s f2:fu bd bu f du fd gn2:gnu b2 bu ed eu ed//c2:cu gn3 b cd eu gd bu bd e gd b bd//d2:du b bu f fu bd e2:eu b bu ed gnu bd//c2:cu gn3 b cd eu gnd bu bd e gd b bd//ds2:dsu b bu gn du dd e2:eu b3 cu gn b bd//d2:du b bu gn du dd e2:eu b3 du gd b dd//c2:cu g bu ed eu b bu bd e gd b ed//f2:fu e bu g fu c3 f2:fu e a f fu cd]" @=> string V3_M_1_8_P;
"[sx12//sx12//sx12//sx12//sx12//sx12//sx12//sx12]" @=> string V3_M_1_8_R;



EZscore part1;
part1.setPitch(V1_M_1_8_P);
part1.setRhythm(V1_M_1_8_R);
//part1.printPitchRhythm();

EZscore part2;
part2.setPitch(V2_M_1_8_P);
part2.setRhythm(V2_M_1_8_R);


EZscore part3;
part3.setPitch(V3_M_1_8_P);
part3.setRhythm(V3_M_1_8_R);


// EZscore array to contain all parts

EZscore fullScore[];

[part1, part2, part3] @=> fullScore;

0 => int total_voices;
for(int i; i < fullScore.size(); i++)
{
    fullScore[i].n_voices +=> total_voices;
}


//---------------------------------------------------------------------
// Testing playback
//---------------------------------------------------------------------

72 => int bpm;

ScorePlayer player[fullScore.size()];

for(int i; i < fullScore.size(); i++)
{
    ScorePlayer sp;
    sp.init(fullScore[i]);
    bpm => sp.local_bpm;
    sp @=> player[i];
}


for(int i; i < player.size(); i++)
{
    player[i].pitches @=> int pitches[][];
    spork ~ player[i].play();
}


while(true)
{
    1::second => now;
}