import React, { useState } from "react";
import Title from "../components/Title";
import { useLang } from "../context/Lang";

import { GameStates } from "../helpers/GameStates";
import { GameTypes } from "../helpers/GameTypes";
import { Players } from "../helpers/Player";
import { Teams } from "../helpers/Teams";

import './TeamsScene.scss';

interface Props {
    show: boolean;
    selectedTeam: Teams;
    setSelectedTeam: (team: Teams) => void;
    gameType: GameTypes|null;
    players: Players;
    scene: GameStates;
}

const TeamsScene: React.FC<Props> = ({ show, setSelectedTeam, gameType, players, scene, selectedTeam }) => {
    const { t } = useLang();
    const [showAlert, setShowAlert] = useState<string|null>(null);
    
    const setTeam = (team: Teams) => {
        if ((scene === GameStates.FirstHalf || scene === GameStates.SecondHalf) && selectedTeam !== Teams.None) {
            setShowAlert(t('cantSwitchTeam').toString());
        } else {
            setSelectedTeam(team);

            if (navigator.userAgent.includes('VeniceUnleashed')) {
                WebUI.Call('DispatchEventLocal', 'WebUISetSelectedTeam', team);
            }
        }
    }

    return (
        <>
            {show &&
                <div id="pageTeams" className="page">
                    {t("selectATeam") !== undefined &&
                        <Title text={t("selectATeam").toString()}/>
                    }

                    <div className="teamsList">
                        <button className={"btn border-btn primary"} onClick={() => setTeam(Teams.Attackers)}>
                            {t('attackers')} 
                            {players[Teams.Attackers].length !== undefined &&
                                <span className="info">
                                    ({players[Teams.Attackers].length.toString()} {t('players')})
                                </span>
                            }
                        </button>
                        <button className={"btn border-btn secondary"} onClick={() => setTeam(Teams.Defenders)}>
                            {t('defenders')} 
                            {players[Teams.Defenders].length !== undefined &&
                                <span className="info">
                                    ({players[Teams.Defenders].length.toString()} {t('players')})
                                </span>
                            }
                        </button>
                        {(gameType !== null && gameType === GameTypes.Public) &&
                            <button className={"btn border-btn"} onClick={() => setTeam(Teams.AutoJoin)}>{t('autoJoin')}</button>
                        }
                        <hr/>
                        <button className={"btn border-btn disabled"}>{t('spectator')}</button>
                    </div>
                    {showAlert !== null &&
                        <div className={"infoBox"}>
                            <h1>{showAlert}</h1>
                        </div>
                    }

                    {t("closeTeamWindow") !== undefined &&
                        <Title text={t("closeTeamWindow").toString()} bottom={true} />
                    }
                </div>
            }
        </>
    );
};

export default TeamsScene;
