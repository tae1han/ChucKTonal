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
EZscore part2(part2mel, part2rhy);
EZscore part3(part3mel, part3rhy);

part1.printContents();

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

while(true)
{
    for(int i; i < player.size(); i++)
    {
        spork ~ player[i].play();
    }
    (part1.totalDuration / bpm)::minute => now;
}