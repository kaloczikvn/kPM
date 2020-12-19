import React, { useEffect } from "react";
import { Teams } from "../helpers/Teams";

interface Props {
    gameWon: boolean|null;
    winningTeam: Teams|null;
    afterInterval: () => void;
}

const GameEndInfoBox: React.FC<Props> = ({ gameWon, winningTeam, afterInterval }) => {
    useEffect(() => {
        const interval = setInterval(() => {
            afterInterval();
        }, 10000);
        return () => {
            clearInterval(interval);
        }
    }, []);

    return (
        <>
            <div className={"roundEndInfoBox gameEndInfoBox fadeInTop " + ((winningTeam !== null ? ((winningTeam === Teams.Attackers) ?  'defenders' : 'attackers') : ''))}>
                {winningTeam !== null
                ?
                    <>
                        <h1>Your team {gameWon ? 'won' : 'lost'}</h1>
                    </>
                :
                    <>
                        <h1>Draw</h1>
                    </>
                }
            </div>
        </>
    );
};

GameEndInfoBox.defaultProps = {
    gameWon: false,
    winningTeam: null,
};

export default GameEndInfoBox;
