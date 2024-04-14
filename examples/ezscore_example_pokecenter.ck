///////////////////////////////////////////////////////////////////////
// EZ score: score4-style notation input
// Tutorial examples - Playback and multi-part scores
//
// This file contains a ScorePlayer class meant to facilitate playback
// of EZscore objects. It also allows for stacking of multiple parts 
// to be played simultaneously.
//
// NOTE: requires ezscore.ck
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

    fun ScorePlayer(EZscore s)
    {
        init(s);
    }
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
        bus.gain(.25);
        for (int i; i < n_voices; i++)
        {
            oscs[i] => envs[i] => bus => dac;
            oscs[i].gain(1.0/(n_voices $ float));
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
// Example: simple three part score
//---------------------------------------------------------------------

// First 4 measures of Pokemon Center Theme from Pokemon Red/Blue

"[k2s d5 ad du au _a g f//e c r a g//c5 a c f _f e c//d f r d c b a]" @=> string part1mel;
"[e e e e _e q e//e e q q q//ex4 _e q e//e e q e e e e]" @=> string part1rhy;

"[k2s f4 es f du _d c b a//b a g f e f e a//a e a c _c b a g//f a b c a e]" @=> string part2mel;
"[ex4 _e ex3//ex8//ex4 _e ex3//ex4 q q]" @=> string part2rhy;

"[k2s d3 f d f d f g f//e a e a e a e a//e a e a e a g a//f a f a f a g a]" @=> string part3mel;
"[ex8//ex8//ex8//ex8]" @=> string part3rhy;

EZscore part1(part1mel, part1rhy);
// part1.setPitch(part1mel);
// part1.setRhythm(part1rhy);
part1.shuffle(2);
part1.printContents();

EZscore part2(part2mel, part2rhy);
// part2.setPitch(part2mel);
// part2.setRhythm(part2rhy);
part2.shuffle(2);

EZscore part3(part3mel, part3rhy);
// part3.setPitch(part3mel);
// part3.setRhythm(part3rhy);
part3.shuffle(2);
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

110 => int bpm;

ScorePlayer player[fullScore.size()];

for(int i; i < fullScore.size(); i++)
{
    ScorePlayer sp(fullScore[i]);
    //sp.init(fullScore[i]);
    bpm => sp.local_bpm;
    sp @=> player[i];
}

for(int i; i < player.size(); i++)
{
    spork ~ player[i].play();
}

while(true)
{
    1::second => now;
}