import React, { useEffect, useState } from "react";

import plantAudio from '../assets/audio/alarm.wav';

interface Props {
    bombSite: string | null;
    afterInterval: () => void;
}

const BombPlantInfoBox: React.FC<Props> = ({ bombSite, afterInterval }) => {
    /*const [audio] = useState(new Audio(plantAudio));
    const [playing, setPlaying] = useState<boolean>((bombSite !== null));

    useEffect(() => {
        audio.volume = 0.4;
        audio.loop = false;
        playing ? audio.play() : audio.pause();
    }, [playing]);

    useEffect(() => {
        audio.addEventListener('ended', () => {
            setPlaying(false);
            
        });
        return () => {
            audio.removeEventListener('ended', () => {
                setPlaying(false);
            });
        };
    }, []);*/

    useEffect(() => {
        const interval = setInterval(() => {
            afterInterval();
        }, 4000);
        return () => {
            clearInterval(interval);
        }
    }, []);

    return (
        <>
            {bombSite !== null &&
                <div className={"roundEndInfoBox gameEndInfoBox fadeInTop defenders"}>
                    <h2>Bomb planted on</h2>
                    <h1>{bombSite} site</h1>
                </div>
            }
        </>
    );
};

BombPlantInfoBox.defaultProps = {
    bombSite: null,
};

export default BombPlantInfoBox;
