import React from "react";
import { useLang } from "../context/Lang";
import { GameTypes } from "../helpers/GameTypes";

import './TutorialBox.scss';

interface Props {
    gameType: GameTypes|null;
}

const TutorialBox: React.FC<Props> = ({ gameType }) => {
    const { t } = useLang();
    
    return (
        <>
            <div className="tutorialBox">
                <div className="head">
                    {t('instructions')}
                </div>
                <div className="body">
                    <p>
                        {t('promodStringIntro')}
                        <br/><br/>
                        <b>{t('Warmup')}</b>
                        <br/>
                        {t('promodStringWarmup')}
                        {(gameType === GameTypes.Public) &&
                            <>
                                {t('promodStringWarmupPlayers')}
                            </>
                        }
                        <br/><br/>
                        <b>{t('objective')}</b>
                        <br/>
                        <b className="primary">{t('attackers')}</b>: {t('promodStringAttackers')}
                        <br/><br/>
                        <b className="secondary">{t('defenders')}</b>: {t('promodStringDefenders')}
                        <br/><br/>
                        <b>{t('plantingDefusing')}</b>
                        <br/>
                        {t('promodStringPlantDefuse')}
                    </p>
                </div>
            </div>
        </>
    );
};

export default TutorialBox;
