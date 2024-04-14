// Ignoring Graphic information for now but could be easily added

public class MusicXML {
    
    string header[0][0];
    string score[0][0][0];

    "&" => string delim;

    //Xml chugin 
    XML xml;

    function void read(string name){

        if(!xml.open(me.dir() + name)){
            <<<  "[Chuck] MusicXML: Could not open",me.dir() + name >>>;
            me.exit();
        } 

        xml.pushTag("score-partwise",0);

        if(xml.tagExists("part-list",0)){
            xml.pushTag("part-list",0);
            xml.getNumTags("score-part") => int parts;
            
            for(int i; i < parts; i++){
                string headerTemp[0];
                xml.pushTag("score-part",i);

                xml.getStringValue("part-name","R",0) => string name;
                xml.getIntValue("midi-instrument:midi-channel",0,0) => int channel;
                xml.getIntValue("midi-instrument:midi-program",0,0) => int program;
                xml.getFloatValue("midi-instrument:volume",0,0) => float volume;
                xml.getFloatValue("midi-instrument:pan",0,0) => float pan;

                headerTemp << name;
                headerTemp << Std.itoa(channel);
                headerTemp << Std.itoa(program);
                headerTemp << Std.ftoa(volume,4);
                headerTemp << Std.ftoa(pan,4);

                header << headerTemp;

                xml.popTag();
            }
        }

        xml.getNumTags("score-part") => int parts;

        xml.popTag();

        for(int i; i < parts; i++){

            xml.pushTag("part",i);

            xml.getIntValue("measure:attributes:divisions",0,0) => int divisions;
            xml.getIntValue("measure:attributes:key:fifths",0,0) => int key;
            xml.getIntValue("measure:attributes:time:beats",0,0) => int beats;
            xml.getIntValue("measure:attributes:time:beat-type",0,0) => int beatType;
            xml.getIntValue("measure:attributes:staves",1,0) => int staves;

            header[i] << Std.itoa(divisions);
            header[i] << Std.itoa(key);
            header[i] << Std.itoa(beats);
            header[i] << Std.itoa(beatType);
            header[i] << Std.itoa(staves);

            string part[0][0];
            xml.getNumTags("measure") => int measures;

            for(int j; j < measures; j++){

                xml.pushTag("measure",j);
                xml.getNumTags("note") => int notes;
                string measure[0];
                int toRemove[0];
                int whichStaff[0];

                for(int k; k < notes; k++){

                    xml.pushTag("note",k);
                    xml.getIntValue("duration",0,0) => int duration;
                    xml.getIntValue("pitch:octave",0,0) => int octave;
                    xml.getStringValue("pitch:step","R",0) => string step;
                    xml.getIntValue("pitch:alter",0,0) => int alter;
                    xml.getIntValue("staff",1,0) => int staff;
                    whichStaff << staff;
            
                    if(xml.tagExists("chord",0)){
                        measure[k-1] + delim + step + Std.itoa(alter) + Std.itoa(octave) + Std.itoa(duration) => string temp;
                        measure << temp;
                        toRemove << k-1;
                    } else {
                        measure << step + Std.itoa(alter) + Std.itoa(octave) + Std.itoa(duration);
                    }
                    xml.popTag();
                }
                
                for(toRemove.cap()-1 => int n; n > -1; n--){
                    measure.popOut(toRemove[n]);
                    whichStaff.popOut(toRemove[n]);
                }
                if(staves > 1){
                    for(int r; r < staves; r++){
                        string tempHolder[0];
                        for(int s; s < whichStaff.cap(); s++){
                            if(whichStaff[s] == r+1){
                                tempHolder << measure[s];
                            } 
                        }
                        part << tempHolder;
                    }
                } else {
                    part << measure;
                }
                xml.popTag();
            }
            score << part;
            xml.popTag();
        }
    }
}
