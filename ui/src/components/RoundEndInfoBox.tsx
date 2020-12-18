import React, { useState, useEffect } from "react";
import { Teams } from "../helpers/Teams";

interface Props {
    roundWon: boolean;
    winningTeam: Teams;
    afterDisaper: () => void;
}

const RoundEndInfoBox: React.FC<Props> = ({ roundWon, winningTeam, afterDisaper }) => {
    const [show, setShow] = useState<boolean>(true);

    useEffect(() => {
        setShow(true);
        const interval = setInterval(() => {
            setShow(false);
            afterDisaper();
        }, 5000);
        return () => {
            clearInterval(interval);
        }
    }, []);
    
    return (
        <>
            {show &&
                <div className={"roundEndInfoBox fadeInTop " + ((winningTeam === Teams.Attackers) ? 'defenders' : 'attackers')}>
                    <h2>Round {roundWon ? 'Won' : 'Lost'}</h2>
                    <h1>{(winningTeam === Teams.Attackers) ? 'Attackers' : 'Defenders'} won</h1>
                </div>
            }
        </>
    );
};

RoundEndInfoBox.defaultProps = {
    roundWon: false,
    winningTeam: Teams.Attackers,
};

export default RoundEndInfoBox;
