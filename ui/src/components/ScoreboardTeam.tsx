import React from "react";
import { useLang } from "../context/Lang";
import { GameStates } from "../helpers/GameStates";
import { Player } from "../helpers/Player";
import { Teams } from "../helpers/Teams";
import ScoreboardPlayer from "./ScoreboardPlayer";

interface Props {
    team: Teams;
    score: number;
    players?: Player[];
    gameState: GameStates;
}

const ScoreboardTeam: React.FC<Props> = ({ team, score, players, gameState }) => {
    const { t } = useLang();

    const getAlivePlayersCount = () => {
        if (players !== undefined && players.length > 0) {
            var alive = Object.values(players).filter(item => item.isDead === false);
            return alive.length;
        } else {
            return 0;
        }
    }

    return (
        <>
            <div className={"team " + ((team === Teams.Attackers) ? 'attackers' : 'defenders') + ' gameState' + gameState.toString()} >
                <div className="headerBar">
                    <div className="teamName">
                        {(team === Teams.Attackers) ? t('attackers') : t('defenders')}
                        <span className="alive">{getAlivePlayersCount()} {t("alive")}</span>
                    </div>
                    <div className="point">{score??0}</div>
                </div>
                <div className="playersHolderHeader">
                    <div className="playerPing">{t("ping")}</div>

                    {(gameState === GameStates.Warmup) &&
                        <div className="playerReady">{t("ready")}</div>
                    }

                    <div className="playerName">{t("name")}</div>
                    <div className="playerKill">{t("kill")}</div>
                    <div className="playerDeath">{t("death")}</div>
                </div>
                <div className="playersHolder">
                    <div className="playersHolderInner">
                        {(players !== undefined && players.length > 0)
                        ?
                            players.map((player: Player, key: number) => (
                                <ScoreboardPlayer player={player} key={key} gameState={gameState} />
                            ))
                        :
                            <div className="noPlayers">{t("noPlayers")}</div>
                        }
                    </div>
                </div>
            </div>
        </>
    );
};

export default ScoreboardTeam;
