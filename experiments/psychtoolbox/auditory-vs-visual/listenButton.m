function [resp, time] = listenButton(offset)

while true
    Datapixx('RegWrRd');
    kbcheck = dec2bin(Datapixx('GetDinValues'));

    if kbcheck(end-offset) == '1'
        for i_but = 1:9
            buttonBox(i_but) = str2num(kbcheck(end-9+i_but));
        end
        
        resp = find(buttonBox);
        time = GetSecs;
        if length(resp) == 1
            break;
        end
    end
end
