import React, { useEffect } from "react";
import { useLang } from "../context/Lang";
import { Teams } from "../helpers/Teams";

interface Props {
    gameWon: boolean|null;
    winningTeam: Teams|null;
    afterInterval: () => void;
}

const GameEndInfoBox: React.FC<Props> = ({ gameWon, winningTeam, afterInterval }) => {
    const { t } = useLang();
    
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
                        <h1>{t('yourTeam')} {gameWon ? t('won') : t('lost')}</h1>
                    </>
                :
                    <>
                        <h1>{t('draw')}</h1>
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
