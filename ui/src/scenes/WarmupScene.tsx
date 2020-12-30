import React from "react";
import { useLang } from "../context/Lang";
import { Player, Players } from "../helpers/Player";

import './WarmupScene.scss';

interface Props {
    rupProgress: number;
    clientPlayer: Player;
    players: Players;
}

const WarmupScene: React.FC<Props> = ({ rupProgress, clientPlayer }) => {
    const { t } = useLang();
    
    return (
        <>
            <div id="pageWarmup" className="page">

                <div id="tutorial">
                    <div className="keyHolder keyF9">
                        <span>F9</span>
                        <h3>{t('teams')}</h3>
                    </div>
                    <div className="keyHolder keyF10">
                        <span>F10</span>
                        <h3>{t('loadouts')}</h3>
                    </div>
                </div>

                <div className={"infoBox " + ((clientPlayer !== undefined && clientPlayer.isReady) ? "ready" : "notReady")}>
                    <div className="rupProgress" style={{width: rupProgress + "%"}}></div>
                    {(clientPlayer !== undefined && clientPlayer.isReady)
                    ?
                        <>
                            <h1>{t('youAreReady')}</h1>
                            <h3>{t('holdInteractToNotReady')}</h3>
                        </>
                    :
                        <>
                            <h1>{t('youAreNotReady')}</h1>
                            <h3>{t('holdInteractToReady')}</h3>
                        </>
                    }
                </div>
            </div>
        </>
    );
};

export default WarmupScene;
