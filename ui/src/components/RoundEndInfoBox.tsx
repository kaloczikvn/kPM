import React, { useState, useEffect } from "react";
import { useLang } from "../context/Lang";
import { Teams } from "../helpers/Teams";

interface Props {
    roundWon: boolean;
    winningTeam: Teams;
    afterDisaper: () => void;
}

const RoundEndInfoBox: React.FC<Props> = ({ roundWon, winningTeam, afterDisaper }) => {
    const { t } = useLang();
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
                    <h2>{t('round')} {roundWon ? t('won') : t('lost')}</h2>
                    <h1>{(winningTeam === Teams.Attackers) ? t('attackers') : t('defenders')} {t('won')}</h1>
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
